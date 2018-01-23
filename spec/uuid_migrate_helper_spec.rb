require_relative 'spec_helper'

class BasicMigration < ActiveRecordMigration
  def change
    reversible do |dir|
      dir.up do
        enable_extension 'pgcrypto'

        primary_key_to_uuid :students
        columns_to_uuid :students, :city_id, :institution_id
      end

      dir.down do
        raise ActiveRecord::IrreversibleMigration
      end
    end
  end
end

class MigrateAllOneGo < ActiveRecordMigration
  def change
    reversible do |dir|
      dir.up do
        enable_extension 'pgcrypto'

        primary_key_to_uuid :cities
        primary_key_to_uuid :colleges
        primary_key_to_uuid :schools

        primary_key_to_uuid :students
        columns_to_uuid :students, :city_id, :institution_id
      end

      dir.down do
        raise ActiveRecord::IrreversibleMigration
      end
    end
  end
end

class MigrateWithFk < ActiveRecordMigration
  def change
    reversible do |dir|
      dir.up do
        enable_extension 'pgcrypto'

        primary_key_and_all_references_to_uuid :cities
      end

      dir.down do
        raise ActiveRecord::IrreversibleMigration
      end
    end
  end
end

class MigrateStep01 < ActiveRecordMigration
  def change
    reversible do |dir|
      dir.up do
        enable_extension 'pgcrypto'

        primary_key_to_uuid :cities
        primary_key_to_uuid :colleges

        primary_key_to_uuid :students
        columns_to_uuid :students, :city_id

        change_column :students, :institution_id, :string
        polymorphic_column_data_for_uuid :students, :institution, 'College'
      end

      dir.down do
        raise ActiveRecord::IrreversibleMigration
      end
    end
  end
end

class MigrateStep02 < ActiveRecordMigration
  def change
    reversible do |dir|
      dir.up do
        primary_key_to_uuid :schools
        columns_to_uuid :students, :institution_id
      end

      dir.down do
        raise ActiveRecord::IrreversibleMigration
      end
    end
  end
end

describe Webdack::UUIDMigration::Helpers do
  def initial_setup
    init_database
    create_initial_schema
    reset_columns_data      # Ensure to reset the column data before sample data creation.
    populate_sample_data
  end

  def reset_columns_data
    [City, College, School, Student].each{|klass| klass.reset_column_information}
  end

  def key_relationships
    [
        Student.order(:name).map { |s| [s.name, s.city ? s.city.name : nil, s.institution ? s.institution.name : nil] },
        City.order(:name).map { |c| [c.name, c.students.order(:name).map(&:name)] },
        School.order(:name).map { |s| [s.name, s.students.order(:name).map(&:name)] },
        College.order(:name).map { |c| [c.name, c.students.order(:name).map(&:name)] }
    ]
  end

  before(:each) do
    initial_setup
  end

  describe 'Basic Test' do
    it 'should migrate keys correctly' do
      # Select a random student
      student = Student.all.to_a.sample

      # Store these values to check against later
      original_name= student.name
      original_ids= [student.id, student.city_id, student.institution_id].map{|i| i.to_i}

      # Migrate and verify that all indexes and primary keys are intact
      expect {
        BasicMigration.migrate(:up)
        reset_columns_data
      }.to_not change {
        indexes= Student.connection.indexes(:students).sort_by { |i| i.name }.map do |i|
          [i.table, i.name, i.unique, i.columns, i.lengths, i.orders, i.where]
        end

        [indexes, Student.connection.primary_key(:students)]
      }

      # Verify that our data is still there
      student= Student.where(name: original_name).first

      # Verify that data in id columns have been migrated to UUID by verifying the format
      [student.id, student.city_id, student.institution_id].each do |id|
        expect(id).to match(/^0{8}-0{4}-0{4}-0{4}-\d{12}$/)
      end

      # Verify that it is possible to retirve original id values
      ids= [student.id, student.city_id, student.institution_id].map{|i| i.gsub('-','').to_i}
      expect(ids).to eq(original_ids)

      # Verify that schema reprts the migrated columns to be uuid type
      columns= Student.connection.columns(:students)
      [:id, :city_id, :institution_id].each do |column|
        expect(columns.find{|c| c.name == column.to_s}.type).to eq :uuid
      end

      # Verify that primary key has correct default
      expect(columns.find{|c| c.name == 'id'}.default_function).to eq 'gen_random_uuid()'
    end
  end

  it 'should migrate entire database in one go' do
    expect {
      MigrateAllOneGo.migrate(:up)
      reset_columns_data
    }.to_not change {
      key_relationships
    }
  end

  it 'should migrate a primary key and all columns referencing it using foreign keys', rails_4_2_or_newer: true do
    # Create 2 more tables similar to the way new version of Rails will do
    create_tables_with_fk

    # Add Foreign key for this reference as well
    ActiveRecord::Base.connection.add_foreign_key :students, :cities

    expect {
      MigrateWithFk.migrate(:up)
      reset_columns_data
    }.to_not change {
      key_relationships
    }
  end

  it 'should handle nulls' do
    Student.create(name: 'Student without city or institution')

    expect {
      MigrateAllOneGo.migrate(:up)
      reset_columns_data
    }.to_not change {
      key_relationships
    }
  end

  it 'should migrate in steps for polymorphic association' do
    expect {
      MigrateStep01.migrate(:up)
      reset_columns_data
    }.to_not change {
      key_relationships
    }

    expect {
      MigrateStep02.migrate(:up)
      reset_columns_data
    }.to_not change {
      key_relationships
    }
  end

  it 'should allow running same migration data even if it was already migrated' do
    expect {
      MigrateStep01.migrate(:up)
      # Run again
      MigrateStep01.migrate(:up)
      reset_columns_data
    }.to_not change {
      key_relationships
    }

    expect {
      MigrateStep02.migrate(:up)
      # Run again
      MigrateStep02.migrate(:up)
      reset_columns_data
    }.to_not change {
      key_relationships
    }
  end

  it 'should allow updation, deletion, and new entity creation' do
    MigrateAllOneGo.migrate(:up)
    reset_columns_data

    # Select a random student
    student = Student.all.to_a.sample

    id= student.id
    student.name= 'New student 01'
    student.save
    student = Student.find(id)

    expect(student.name).to eq 'New student 01'

    expect { student.destroy }.to change { Student.count }.by(-1)

    expect {Student.find(id)}.to raise_exception(ActiveRecord::RecordNotFound)

    student= Student.create(
        name: 'New student 02',
        city: City.where(name: 'City 2').first,
        institution: School.where(name: 'School 1').first
    )

    expect(City.where(name: 'City 2').first.students.where(name: 'New student 02').first.name).to eq 'New student 02'
    expect(School.where(name: 'School 1').first.students.where(name: 'New student 02').first.name).to eq 'New student 02'

    College.where(name: 'College 3').first.students << student

    student.reload

    expect(student.institution.name).to eq 'College 3'
  end
end
