require_relative 'spec_helper'

class MigrationBase < ActiveRecord::Migration
  def change
    create_table :states, primary_key: :stateid do |t|
      t.string :name
    end

    enable_extension 'uuid-ossp'
  end
end

class Migration01 < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        primary_key_to_uuid :states
      end

      dir.down do
        raise ActiveRecord::IrreversibleMigration
      end
    end
  end
end

class Migration02 < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        primary_key_to_uuid :states, primary_key: :stateid
      end

      dir.down do
        raise ActiveRecord::IrreversibleMigration
      end
    end
  end
end

class Migration03 < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        primary_key_to_uuid :states, default: 'uuid_generate_v1()'
      end

      dir.down do
        raise ActiveRecord::IrreversibleMigration
      end
    end
  end
end

class State < ActiveRecord::Base
end

describe Webdack::UUIDMigration::Helpers do
  def initial_setup
    init_database

    MigrationBase.migrate(:up)

    (0..9).each do |i|
      State.create(name: "State #{i}")
    end
  end

  def reset_columns_data
    [State].each{|klass| klass.reset_column_information}
  end

  def key_relationships
    [
        State.order(:name).map { |s| [s.name] }
    ]
  end

  before(:each) do
    initial_setup
  end

  it 'should migrate table with custom primary_key' do
    expect {
      Migration01.migrate(:up)
      reset_columns_data
    }.to_not change {
      key_relationships
    }

    expect(State.connection.primary_key(:states)).to eq 'stateid'
  end

  it 'should honour primary_key with explicit hint' do
    expect {
      Migration02.migrate(:up)
      reset_columns_data
    }.to_not change {
      key_relationships
    }

    expect(State.connection.primary_key(:states)).to eq 'stateid'
  end

  it 'should honour default' do
    expect {
      Migration03.migrate(:up)
      reset_columns_data
    }.to_not change {
      key_relationships
    }

    default_function = State.connection.columns(:states).find { |c| c.name == 'stateid' }.default_function
    expect(default_function).to eq 'uuid_generate_v1()'
  end

end
