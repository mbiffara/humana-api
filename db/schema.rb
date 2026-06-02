# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_06_02_201705) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "experience_id", null: false
    t.bigint "client_id"
    t.string "reference", null: false
    t.integer "guests", default: 1, null: false
    t.date "starts_on"
    t.date "ends_on"
    t.string "status", default: "inquiry", null: false
    t.integer "amount_cents", default: 0, null: false
    t.string "currency", default: "USD", null: false
    t.integer "commission_cents", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_bookings_on_client_id"
    t.index ["experience_id"], name: "index_bookings_on_experience_id"
    t.index ["organization_id"], name: "index_bookings_on_organization_id"
    t.index ["reference"], name: "index_bookings_on_reference", unique: true
    t.index ["status"], name: "index_bookings_on_status"
  end

  create_table "clients", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.string "email"
    t.string "phone"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "email"], name: "index_clients_on_organization_id_and_email"
    t.index ["organization_id"], name: "index_clients_on_organization_id"
  end

  create_table "experiences", force: :cascade do |t|
    t.bigint "hotel_id", null: false
    t.string "slug", null: false
    t.string "kind", default: "retreat", null: false
    t.string "title", null: false
    t.text "description"
    t.string "location"
    t.string "country"
    t.string "country_code", limit: 2
    t.date "starts_on"
    t.date "ends_on"
    t.integer "price_cents", default: 0, null: false
    t.string "currency", default: "USD", null: false
    t.decimal "commission_rate", precision: 5, scale: 4, default: "0.0", null: false
    t.integer "capacity"
    t.string "image_url"
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code"], name: "index_experiences_on_country_code"
    t.index ["hotel_id"], name: "index_experiences_on_hotel_id"
    t.index ["kind"], name: "index_experiences_on_kind"
    t.index ["slug"], name: "index_experiences_on_slug", unique: true
    t.index ["status"], name: "index_experiences_on_status"
  end

  create_table "hotels", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.string "city"
    t.string "country"
    t.string "country_code", limit: 2
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.boolean "certified", default: false, null: false
    t.string "wellness_standard"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code"], name: "index_hotels_on_country_code"
    t.index ["organization_id"], name: "index_hotels_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "kind", default: "agency", null: false
    t.string "status", default: "pending", null: false
    t.string "city"
    t.string "country"
    t.string "country_code", limit: 2
    t.string "contact_email"
    t.string "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_organizations_on_kind"
    t.index ["status"], name: "index_organizations_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name"
    t.string "role", default: "member", null: false
    t.string "locale", default: "en", null: false
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
  end

  add_foreign_key "bookings", "clients"
  add_foreign_key "bookings", "experiences"
  add_foreign_key "bookings", "organizations"
  add_foreign_key "clients", "organizations"
  add_foreign_key "experiences", "hotels"
  add_foreign_key "hotels", "organizations"
  add_foreign_key "users", "organizations"
end
