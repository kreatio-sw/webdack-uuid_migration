# encoding: UTF-8

def create_initial_schema
  ActiveRecord::Schema.define(version: 20140117141611) do

    # These are extensions that must be enabled in order to support this database
    enable_extension "plpgsql"

    create_table "cities", force: true do |t|
      t.string "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "colleges", force: true do |t|
      t.string "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "schools", force: true do |t|
      t.string "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "students", force: true do |t|
      t.string "name"
      t.integer "city_id"
      t.string "institution_type"
      t.integer "institution_id"
      t.datetime "created_at"
      t.datetime "updated_at"

      t.index "city_id"
      t.index ["institution_type", "institution_id"]
    end

  end
end

def create_tables_with_fk
  connection = ActiveRecord::Base.connection

  connection.create_table "dummy01", force: true do |t|
    t.string "name"
    t.references "city", index: true, foreign_key: {on_update: :cascade, on_delete: :nullify}
  end

  connection.create_table "dummy02", force: true do |t|
    t.string "name"
    t.references "city", index: true, foreign_key: {on_update: :restrict, on_delete: :restrict}
  end
end