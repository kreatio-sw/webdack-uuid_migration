require_relative 'schema_helpers'

module Webdack
  module UUIDMigration
    module Helpers
      include SchemaHelpers


      # Converts primary key from Serial Integer to UUID, migrates all data by left padding with 0's
      #   sets gen_random_uuid() as default for the column
      #
      # @param table [Symbol]
      # @param options [hash]
      # @option options [Symbol] :primary_key if not supplied queries the schema (should work most of the times)
      # @option options [String] :default mechanism to generate UUID for new records, default gen_random_uuid(),
      #           which is Rails 4.0.0 default as well
      # @return [none]
      def primary_key_to_uuid(table, options={})
        default= options[:default] || 'gen_random_uuid()'

        column= connection.primary_key(table)

        execute %Q{ALTER TABLE #{table}
                 ALTER COLUMN #{column} DROP DEFAULT,
                 ALTER COLUMN #{column} SET DATA TYPE UUID USING (#{to_uuid_pg(column)}),
                 ALTER COLUMN #{column} SET DEFAULT #{default}}

        execute %Q{DROP SEQUENCE IF EXISTS #{table}_#{column}_seq} rescue nil
      end

      # Converts a column to UUID, migrates all data by left padding with 0's
      #
      # @param table [Symbol]
      # @param column [Symbol]
      #
      # @return [none]
      def column_to_uuid(table, column)
        execute %Q{ALTER TABLE #{table}
                 ALTER COLUMN #{column} SET DATA TYPE UUID USING (#{to_uuid_pg(column)})}
      end

      # Converts columns to UUID, migrates all data by left padding with 0's
      #
      # @param table [Symbol]
      # @param columns
      #
      # @return [none]
      def columns_to_uuid(table, *columns)
        columns.each do |column|
          column_to_uuid(table, column)
        end
      end

      # Convert an Integer to UUID formatted string by left padding with 0's
      #
      # @param num [Integer]
      # @return [String]
      def int_to_uuid(num)
        '00000000-0000-0000-0000-%012d' % num.to_i
      end

      # Convert data values to UUID format for polymorphic associations. Useful when only few
      # of associated entities have switched to UUID primary keys. Before calling this ensure that
      # the corresponding column_id has been changed to :string (VARCHAR(36) or larger)
      #
      # See Polymorphic References in {file:README.md}
      #
      # @param table[Symbol]
      # @param column [Symbol] it will change data in corresponding <column>_id
      # @param entities [String] data referring these entities will be converted
      def polymorphic_column_data_for_uuid(table, column, *entities)
        list_of_entities= entities.map{|e| "'#{e}'"}.join(', ')
        execute %Q{
                  UPDATE #{table} SET #{column}_id= #{to_uuid_pg("#{column}_id")}
                    WHERE #{column}_type in (#{list_of_entities})
                }
      end

      # Convert primary key of a table and all referring columns to UUID. Useful if migrations were generated
      # with newer version of Rails that automatically creates foreign key constraints in the database.
      #
      # Internally it will query the database to find all tables & columns referring to this primary key as foreign keys
      # and do the following:
      #
      # - Drop all foreign key constraints referring to this primary key
      # - Convert the primary key to UUID
      # - Convert all referring columns to UUID
      # - Restore all foreign keys
      #
      # @param table[Symbol]
      # @note Works only with Rails 4.2 or newer
      def primary_key_and_all_references_to_uuid(table)
        fk_specs = foreign_keys_into(table)

        drop_foreign_keys(fk_specs)

        primary_key_to_uuid(table)

        fk_specs.each do |fk_spec|
          columns_to_uuid fk_spec[:from_table], fk_spec[:column]
        end

        create_foreign_keys(fk_specs.deep_dup)
      end

      private
      # Prepare a fragment that can be used in SQL statements that converts teh data value
      # from integer, string, or UUID to valid UUID string as per Postgres guidelines
      #
      # @param column [Symbol]
      # @return [String]
      def to_uuid_pg(column)
        "uuid(lpad(replace(text(#{column}),'-',''), 32, '0'))"
      end
    end
  end
end

ActiveRecord::Migration.class_eval do
  include Webdack::UUIDMigration::Helpers
end
