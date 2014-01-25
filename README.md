# Webdack::UuidMigration

Helper methods to migrate Integer columns to UUID columns during migrations in PostgreSQL.
It supports migrating primary key columns as well.

## Installation

Add this line to your application's Gemfile:

    gem 'webdack-uuid_migration'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install webdack-uuid_migration

## Usage

- Put `require 'webdack/uuid_migration/helper'` in your migration file.
- Enable `'uuid-ossp'` directly in Postgres database or by adding `enable_extension 'uuid-ossp'` to your migration.
- Use methods from {Webdack::UUIDMigration::Helpers} as appropriate.

Example:

    # You must explicitly require it in your migration file
    require 'webdack/uuid_migration/helper'

    class UuidMigration < ActiveRecord::Migration
      def change
        reversible do |dir|
          dir.up do
            # Good idea to do the following, needs superuser rights in the database
            # Alternatively the extension needs to be manually enabled in the RDBMS
            enable_extension 'uuid-ossp'

            primary_key_to_uuid :students

            primary_key_to_uuid :cities
            primary_key_to_uuid :sections
            columns_to_uuid :students, :city_id, :section_id
          end

          dir.down do
            raise ActiveRecord::IrreversibleMigration
          end
        end
      end
    end

Integer values are converted to UUID by padding 0's to the left. This makes it possible to
retrieve old id in future.

See {Webdack::UUIDMigration::Helpers} for more details. {Webdack::UUIDMigration::Helpers} is mixed
into {ActiveRecord::Migration}, so that all methods can directly be used within migrations.

### Polymorphic references

Migrating Polymorphic references may get tricky if not all the participating entities are getting migrated to
UUID primary keys. If only some of the referenced entities are getting migrated to use UUID primary keys please use the
following steps:

- Change the corresponding <column>_id to String type (at least VARCHAR(36)).
- Call `polymorphic_column_data_for_uuid :table, :column, 'Entity1', 'Entity2', ...`
- Note that :column in is without the _id.
- See {Webdack::UUIDMigration::Helpers#polymorphic_column_data_for_uuid}
- When all remaining references also gets migrated to UUID primary keys, call `columns_to_uuid :table, :column_id`

Example:

    # Student -- belongs_to :institution, :polymorphic => true
    # An institution is either a School or a College
    # College is migrated to use UUID as primary key
    # School uses Integer primary keys

    # Place the following in migration script
        primary_key_to_uuid :colleges
        change_column :students, :institution_id, :string
        polymorphic_column_data_for_uuid :students, :institution, 'College'

    # When School also gets migrated to UUID primary key
        primary_key_to_uuid :schools
        columns_to_uuid :students, :institution_id

    # See the rspec test case in spec folder for full example


## Compatibility

Works only with Rails 4. It uses Rails4's out-of-the-box UUID support for PostgreSQL. Works with Ruby 1.9.3 an 2.0.0.

To run the test suite:

    # Update connection parameters in `spec/support/pg_database_helper.rb`.
    # Postgres user must have rights to create/drop database and create extensions.
    $ bundle exec rspec spec

## Contributing

1. Fork it ( http://github.com/<my-github-username>/webdack-uuid_migration/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
