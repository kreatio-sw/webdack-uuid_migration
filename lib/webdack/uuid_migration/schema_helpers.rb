module Webdack
  module UUIDMigration
    module SchemaHelpers
      def foreign_keys_into(to_table_name)
        to_primary_key = primary_key(to_table_name)


        fk_info = select_all <<-SQL.strip_heredoc
        SELECT t2.oid::regclass::text AS to_table, a2.attname AS primary_key, t1.relname as from_table, a1.attname AS column, c.conname AS name, c.confupdtype AS on_update, c.confdeltype AS on_delete            FROM pg_constraint c
        JOIN pg_class t1 ON c.conrelid = t1.oid
        JOIN pg_class t2 ON c.confrelid = t2.oid
        JOIN pg_attribute a1 ON a1.attnum = c.conkey[1] AND a1.attrelid = t1.oid
        JOIN pg_attribute a2 ON a2.attnum = c.confkey[1] AND a2.attrelid = t2.oid
        JOIN pg_namespace t3 ON c.connamespace = t3.oid
        WHERE c.contype = 'f'
          AND t2.oid::regclass::text = #{quote(to_table_name)}
          AND a2.attname = #{quote(to_primary_key)}
        ORDER BY t1.relname, a1.attname
        SQL

        fk_info.map do |row|
          options = {
              to_table: row['to_table'],
              primary_key: row['primary_key'],
              from_table: row['from_table'],
              column: row['column'],
              name: row['name']
          }

          options[:on_delete] = extract_foreign_key_action(row['on_delete'])
          options[:on_update] = extract_foreign_key_action(row['on_update'])

          options
        end
      end

      def drop_foreign_keys(foreign_keys)
        foreign_keys.each do |fk_key_spec|
          foreign_key_spec = fk_key_spec.dup
          from_table = foreign_key_spec.delete(:from_table)
          remove_foreign_key from_table, name: foreign_key_spec[:name]
        end
      end

      def create_foreign_keys(foreign_keys)
        foreign_keys.each do |fk_key_spec|
          foreign_key_spec = fk_key_spec.dup
          from_table = foreign_key_spec.delete(:from_table)
          to_table = foreign_key_spec.delete(:to_table)
          add_foreign_key from_table, to_table, foreign_key_spec
        end
      end
    end
  end
end
