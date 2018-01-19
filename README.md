# Webdack::UuidMigration

[![Build Status](https://travis-ci.org/kreatio-sw/webdack-uuid_migration.svg?branch=master)](https://travis-ci.org/kreatio-sw/webdack-uuid_migration)

**This project is actively maintained. Please report issues and/or create
pull requests if you face any issues.** 

Helper methods to migrate Integer columns to UUID columns during migrations in PostgreSQL.
It supports migrating primary key columns as well.

## Documentation

http://www.rubydoc.info/gems/webdack-uuid_migration

## Installation

Add this line to your application's Gemfile:

    gem 'webdack-uuid_migration'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install webdack-uuid_migration
    
This gem is needed only during database migrations. 
Once the database has been migrated in all environments, 
this gem can safely be removed from your applications Gemfile.

## Usage

- Put `require 'webdack/uuid_migration/helpers'` in your migration file.
- Enable `'pgcrypto'` directly in Postgres database or by adding `enable_extension 'pgcrypto'` to your migration.
- Use methods from {Webdack::UUIDMigration::Helpers} as appropriate.

Example:

    # You must explicitly require it in your migration file
    require 'webdack/uuid_migration/helpers'

    class UuidMigration < ActiveRecord::Migration
      def change
        reversible do |dir|
          dir.up do
            # Good idea to do the following, needs superuser rights in the database
            # Alternatively the extension needs to be manually enabled in the RDBMS
            enable_extension 'pgcrypto'

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

### Schema with Foreign Key References

Please see [https://github.com/kreatio-sw/webdack-uuid_migration/issues/4]

This function will only work with Rails 4.2 or newer.

To update a primary key and all columns referencing it please use
{Webdack::UUIDMigration::Helpers#primary_key_and_all_references_to_uuid}. For example:

```
class MigrateWithFk < ActiveRecord::Migration
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
```

Internally it will query the database to find all tables & columns referring to this primary key as foreign keys
and do the following:

- Drop all foreign key constraints referring to this primary key
- Convert the primary key to UUID
- Convert all referring columns to UUID
- Restore all foreign keys

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

Works only with Rails 4 & Rails 5. It uses Rails4's out-of-the-box UUID support for PostgreSQL. Works with following 
Ruby versions:

- 2.0.0
- 2.1.10
- 2.2.8
- 2.3.5
- 2.4.2
 
Tested with Rails 5.0.x and 5.1.x. Reported working with 5.2.0 alpha.

To run the test suite:

    # Update connection parameters in `spec/support/pg_database_helper.rb`.
    # Postgres user must have rights to create/drop database and create extensions.
    $ bundle exec rspec spec

## Credits

- Users of the Gem
- [Felix Bünemann](https://github.com/felixbuenemann) for checking compatibility with Rails 4.1
- [Nick Schwaderer](https://github.com/Schwad) Rials 5.2.x compatibility

## Contributing

1. Fork it ( http://github.com/kreatio-sw/webdack-uuid_migration/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
