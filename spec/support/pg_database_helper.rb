# With thanks to http://7fff.com/2010/12/02/activerecord-dropcreate-database-run-migrations-outside-of-rails/

PG_SPEC = {
    :adapter  => 'postgresql',
    :database => 'webdack_uuid_migration_helper_test',
    :username => 'postgres',
    :encoding => 'utf8'
}

def init_database
# drops and create need to be performed with a connection to the 'postgres' (system) database
  ActiveRecord::Base.establish_connection(PG_SPEC.merge('database' => 'postgres', 'schema_search_path' => 'public'))
# drop the old database (if it exists)
  ActiveRecord::Base.connection.drop_database PG_SPEC[:database]
# create new
  ActiveRecord::Base.connection.create_database(PG_SPEC[:database])
  ActiveRecord::Base.establish_connection(PG_SPEC)
end
