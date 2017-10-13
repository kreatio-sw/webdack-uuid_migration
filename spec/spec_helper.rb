Bundler.setup(:development)

require 'rspec'
require 'active_record'
require 'pg'
require 'webdack/uuid_migration/helpers'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |c|
  if Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new('4.2')
    c.filter_run_excluding rails_4_2_or_newer: true
  end
end

ActiveRecordMigration = if ActiveRecord.version >= Gem::Version.new('5.0.0')
                          ActiveRecord::Migration[5.0]
                        else
                          ActiveRecord::Migration
                        end