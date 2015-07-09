# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150708172845) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "accounts", force: :cascade do |t|
    t.integer  "canvas_id"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "courses", force: :cascade do |t|
    t.integer  "canvas_id"
    t.integer  "account_id"
    t.string   "name"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.hstore   "discussions"
    t.hstore   "files"
    t.hstore   "assignments"
    t.hstore   "grades"
    t.hstore   "participation_and_access"
    t.hstore   "grades_by_assignment"
  end

  create_table "teachers", force: :cascade do |t|
    t.integer  "canvas_id"
    t.string   "name"
    t.string   "sortable_name"
    t.string   "email"
    t.string   "avatar_url"
    t.datetime "last_login"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "school_account"
  end

  create_table "tools", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
