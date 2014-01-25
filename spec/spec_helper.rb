Bundler.setup(:development)

require 'rspec'
require 'active_record'
require 'pg'
require 'webdack/uuid_migration/helpers'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
