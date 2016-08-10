require_relative 'spec_helper'

ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
  include Webdack::UUIDMigration::SchemaHelpers
end

describe Webdack::UUIDMigration::SchemaHelpers, rails_4_2_or_newer: true do
  def initial_setup
    init_database
    create_initial_schema

    # Create 2 more tables similar to the way new version of Rails will do
    create_tables_with_fk
  end

  before(:each) do
    initial_setup

    @connection = ActiveRecord::Base.connection

    # Create one more foreign key constraints
    @connection.add_foreign_key :students, :cities
  end

  it 'should get all foreign keys into a table' do
    foreign_keys_into = @connection.foreign_keys_into(:cities)

    expect(foreign_keys_into).to eq([{:to_table => "cities",
                                      :primary_key => "id",
                                      :from_table => "dummy01",
                                      :column => "city_id",
                                      :name => "fk_rails_d0b87897d5",
                                      :on_delete => :nullify,
                                      :on_update => :cascade},
                                     {:to_table => "cities",
                                      :primary_key => "id",
                                      :from_table => "dummy02",
                                      :column => "city_id",
                                      :name => "fk_rails_bc0a81611b",
                                      :on_delete => :restrict,
                                      :on_update => :restrict},
                                     {:to_table => "cities",
                                      :primary_key => "id",
                                      :from_table => "students",
                                      :column => "city_id",
                                      :name => "fk_rails_c4b8171c0a",
                                      :on_delete => nil,
                                      :on_update => nil}])
  end

  it 'should drop all foreign keys into a table' do
    fk_specs = @connection.foreign_keys_into(:cities)

    @connection.drop_foreign_keys(fk_specs)

    expect(@connection.foreign_keys_into(:cities)).to eq([])
  end

  it 'should drop all recreate all foreign keys into a table' do
    fk_specs = @connection.foreign_keys_into(:cities)

    @connection.drop_foreign_keys(fk_specs)
    @connection.create_foreign_keys(fk_specs)

    expect(@connection.foreign_keys_into(:cities)).to eq(fk_specs)
  end

end
