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

ActiveRecord::Schema[8.0].define(version: 2026_08_15_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "availability_blocks", force: :cascade do |t|
    t.bigint "hotel_id", null: false
    t.bigint "room_type_id", null: false
    t.date "starts_on", null: false
    t.date "ends_on", null: false
    t.integer "units"
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hotel_id"], name: "index_availability_blocks_on_hotel_id"
    t.index ["room_type_id", "starts_on", "ends_on"], name: "index_availability_blocks_on_room_type_and_range"
    t.index ["room_type_id"], name: "index_availability_blocks_on_room_type_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "experience_id"
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
    t.bigint "room_type_id"
    t.bigint "room_id"
    t.bigint "hotel_id"
    t.bigint "retreat_id"
    t.index ["client_id"], name: "index_bookings_on_client_id"
    t.index ["experience_id"], name: "index_bookings_on_experience_id"
    t.index ["hotel_id"], name: "index_bookings_on_hotel_id"
    t.index ["organization_id"], name: "index_bookings_on_organization_id"
    t.index ["reference"], name: "index_bookings_on_reference", unique: true
    t.index ["retreat_id"], name: "index_bookings_on_retreat_id"
    t.index ["room_id"], name: "index_bookings_on_room_id"
    t.index ["room_type_id"], name: "index_bookings_on_room_type_id"
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

  create_table "countries", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", limit: 2, null: false
    t.string "flag_emoji"
    t.string "status", default: "active", null: false
    t.boolean "enabled", default: true, null: false
    t.string "region"
    t.string "currency_code", limit: 3
    t.string "timezone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_countries_on_code", unique: true
    t.index ["enabled"], name: "index_countries_on_enabled"
    t.index ["region"], name: "index_countries_on_region"
    t.index ["status"], name: "index_countries_on_status"
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

  create_table "hotel_amenities", force: :cascade do |t|
    t.bigint "hotel_id", null: false
    t.string "name", null: false
    t.string "category", default: "general", null: false
    t.string "icon"
    t.integer "position", default: 0
    t.boolean "featured", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_hotel_amenities_on_category"
    t.index ["hotel_id", "name"], name: "index_hotel_amenities_on_hotel_id_and_name", unique: true
    t.index ["hotel_id"], name: "index_hotel_amenities_on_hotel_id"
  end

  create_table "hotel_images", force: :cascade do |t|
    t.bigint "hotel_id", null: false
    t.string "image_url", null: false
    t.string "category", default: "general", null: false
    t.integer "position", default: 0, null: false
    t.string "alt_text"
    t.boolean "is_cover", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_hotel_images_on_category"
    t.index ["hotel_id", "is_cover"], name: "index_hotel_images_on_hotel_id_and_is_cover"
    t.index ["hotel_id", "position"], name: "index_hotel_images_on_hotel_id_and_position"
    t.index ["hotel_id"], name: "index_hotel_images_on_hotel_id"
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
    t.string "address"
    t.string "postal_code"
    t.string "phone"
    t.integer "stars"
    t.string "check_in_time", default: "15:00"
    t.string "check_out_time", default: "11:00"
    t.integer "total_rooms"
    t.string "logo_url"
    t.string "website"
    t.string "contact_email"
    t.datetime "onboarding_completed_at"
    t.index ["country_code"], name: "index_hotels_on_country_code"
    t.index ["organization_id"], name: "index_hotels_on_organization_id"
  end

  create_table "inventory_blocks", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "hotel_id", null: false
    t.bigint "room_type_id", null: false
    t.integer "total_rooms", null: false
    t.date "starts_on", null: false
    t.date "ends_on", null: false
    t.integer "cost_per_night_cents", null: false
    t.string "currency", default: "USD", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hotel_id"], name: "index_inventory_blocks_on_hotel_id"
    t.index ["organization_id", "hotel_id", "room_type_id"], name: "idx_inv_blocks_org_hotel_rt"
    t.index ["organization_id"], name: "index_inventory_blocks_on_organization_id"
    t.index ["room_type_id"], name: "index_inventory_blocks_on_room_type_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.string "email", null: false
    t.string "token", null: false
    t.string "role", null: false
    t.bigint "organization_id", null: false
    t.bigint "invited_by_id", null: false
    t.datetime "accepted_at"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
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
    t.string "legal_name"
    t.string "phone"
    t.string "primary_contact"
    t.string "tax_id"
    t.text "description"
    t.string "logo_url"
    t.string "specialties", default: [], array: true
    t.datetime "onboarding_completed_at"
    t.bigint "assigned_office_id"
    t.string "address"
    t.string "bank_account_holder"
    t.string "bank_iban"
    t.string "bank_swift"
    t.string "bank_currency", default: "USD"
    t.string "bank_country"
    t.string "bank_status", default: "pending"
    t.boolean "sponsored", default: false, null: false
    t.boolean "pending_changes", default: false, null: false
    t.text "review_feedback"
    t.datetime "review_feedback_at"
    t.index ["assigned_office_id"], name: "index_organizations_on_assigned_office_id"
    t.index ["kind"], name: "index_organizations_on_kind"
    t.index ["status"], name: "index_organizations_on_status"
  end

  create_table "platform_settings", force: :cascade do |t|
    t.string "platform_name", default: "HUMANA", null: false
    t.string "support_email", default: "ops@humana.global", null: false
    t.string "default_currency", limit: 3, default: "USD", null: false
    t.string "default_language", limit: 2, default: "en", null: false
    t.decimal "agency_commission_rate", precision: 5, scale: 4, default: "0.16", null: false
    t.decimal "office_fee_rate", precision: 5, scale: 4, default: "0.02", null: false
    t.decimal "hotel_net_rate", precision: 5, scale: 4, default: "0.82", null: false
    t.string "terms_url"
    t.string "privacy_url"
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "retreat_activities", force: :cascade do |t|
    t.bigint "retreat_day_id", null: false
    t.string "name", null: false
    t.string "time"
    t.integer "duration_minutes"
    t.integer "position", default: 0, null: false
    t.text "description"
    t.string "category"
    t.string "icon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["retreat_day_id", "position"], name: "index_retreat_activities_on_retreat_day_id_and_position"
    t.index ["retreat_day_id"], name: "index_retreat_activities_on_retreat_day_id"
  end

  create_table "retreat_days", force: :cascade do |t|
    t.bigint "retreat_id", null: false
    t.integer "day_number", null: false
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["retreat_id", "day_number"], name: "index_retreat_days_on_retreat_id_and_day_number", unique: true
    t.index ["retreat_id"], name: "index_retreat_days_on_retreat_id"
  end

  create_table "retreat_facilitators", force: :cascade do |t|
    t.bigint "retreat_id", null: false
    t.string "name", null: false
    t.string "role", default: "lead", null: false
    t.string "specialty"
    t.string "avatar_url"
    t.text "bio"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["retreat_id", "role"], name: "index_retreat_facilitators_on_retreat_id_and_role"
    t.index ["retreat_id"], name: "index_retreat_facilitators_on_retreat_id"
  end

  create_table "retreat_images", force: :cascade do |t|
    t.bigint "retreat_id", null: false
    t.string "image_url", null: false
    t.integer "position", default: 0, null: false
    t.string "alt_text"
    t.boolean "is_cover", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["retreat_id", "is_cover"], name: "index_retreat_images_on_retreat_id_and_is_cover"
    t.index ["retreat_id", "position"], name: "index_retreat_images_on_retreat_id_and_position"
    t.index ["retreat_id"], name: "index_retreat_images_on_retreat_id"
  end

  create_table "retreat_inclusions", force: :cascade do |t|
    t.bigint "retreat_id", null: false
    t.string "name", null: false
    t.string "category", default: "general"
    t.string "icon"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["retreat_id", "position"], name: "index_retreat_inclusions_on_retreat_id_and_position"
    t.index ["retreat_id"], name: "index_retreat_inclusions_on_retreat_id"
  end

  create_table "retreat_pricings", force: :cascade do |t|
    t.bigint "retreat_id", null: false
    t.bigint "room_type_id", null: false
    t.integer "price_per_guest_cents", default: 0, null: false
    t.string "currency", default: "USD", null: false
    t.string "occupancy_label"
    t.integer "max_guests", default: 2
    t.integer "allocated_rooms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["retreat_id", "room_type_id"], name: "index_retreat_pricings_on_retreat_id_and_room_type_id", unique: true
    t.index ["retreat_id"], name: "index_retreat_pricings_on_retreat_id"
    t.index ["room_type_id"], name: "index_retreat_pricings_on_room_type_id"
  end

  create_table "retreats", force: :cascade do |t|
    t.bigint "hotel_id", null: false
    t.bigint "created_by_organization_id", null: false
    t.string "created_by_type", default: "hotel", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "retreat_type", default: "wellness", null: false
    t.integer "duration_nights", default: 3, null: false
    t.date "starts_on"
    t.date "ends_on"
    t.integer "capacity"
    t.string "language", default: "en", null: false
    t.string "status", default: "draft", null: false
    t.text "description"
    t.text "short_description"
    t.string "location"
    t.string "country"
    t.string "country_code", limit: 2
    t.integer "min_price_cents", default: 0
    t.string "currency", default: "USD", null: false
    t.decimal "commission_rate", precision: 5, scale: 4, default: "0.16", null: false
    t.string "cover_image_url"
    t.boolean "featured", default: false, null: false
    t.boolean "certified", default: false, null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code"], name: "index_retreats_on_country_code"
    t.index ["created_by_organization_id"], name: "index_retreats_on_created_by_organization_id"
    t.index ["featured"], name: "index_retreats_on_featured"
    t.index ["hotel_id", "status"], name: "index_retreats_on_hotel_id_and_status"
    t.index ["hotel_id"], name: "index_retreats_on_hotel_id"
    t.index ["retreat_type"], name: "index_retreats_on_retreat_type"
    t.index ["slug"], name: "index_retreats_on_slug", unique: true
    t.index ["status"], name: "index_retreats_on_status"
  end

  create_table "room_images", force: :cascade do |t|
    t.bigint "room_type_id", null: false
    t.string "image_url", null: false
    t.integer "position", default: 0, null: false
    t.string "alt_text"
    t.boolean "is_primary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_type_id", "position"], name: "index_room_images_on_room_type_id_and_position"
    t.index ["room_type_id"], name: "index_room_images_on_room_type_id"
  end

  create_table "room_rate_tiers", force: :cascade do |t|
    t.bigint "room_type_id", null: false
    t.integer "min_rooms", null: false
    t.date "starts_on"
    t.date "ends_on"
    t.integer "price_per_night_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_type_id", "min_rooms"], name: "index_room_rate_tiers_on_room_type_id_and_min_rooms"
    t.index ["room_type_id"], name: "index_room_rate_tiers_on_room_type_id"
  end

  create_table "room_types", force: :cascade do |t|
    t.bigint "hotel_id", null: false
    t.string "name", null: false
    t.string "category", default: "standard", null: false
    t.integer "capacity", default: 2, null: false
    t.decimal "area_sqm", precision: 8, scale: 2
    t.integer "price_per_night_cents", default: 0, null: false
    t.string "currency", default: "USD", null: false
    t.text "description"
    t.string "image_url"
    t.integer "total_rooms"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "bed_type"
    t.string "amenities", default: [], array: true
    t.string "view_type"
    t.string "status", default: "active", null: false
    t.index ["category"], name: "index_room_types_on_category"
    t.index ["hotel_id", "name"], name: "index_room_types_on_hotel_id_and_name", unique: true
    t.index ["hotel_id"], name: "index_room_types_on_hotel_id"
    t.index ["status"], name: "index_room_types_on_status"
  end

  create_table "rooms", force: :cascade do |t|
    t.bigint "hotel_id", null: false
    t.bigint "room_type_id", null: false
    t.string "number", null: false
    t.string "status", default: "available", null: false
    t.boolean "auto_generated", default: false, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "hotel_id, lower((number)::text)", name: "index_rooms_on_hotel_id_and_lower_number", unique: true
    t.index ["hotel_id"], name: "index_rooms_on_hotel_id"
    t.index ["room_type_id", "status"], name: "index_rooms_on_room_type_id_and_status"
    t.index ["room_type_id"], name: "index_rooms_on_room_type_id"
  end

  create_table "stripe_connect_accounts", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "stripe_account_id", null: false
    t.string "onboarding_status", default: "pending", null: false
    t.integer "mrr_cents", default: 0
    t.string "currency", default: "USD", null: false
    t.boolean "payouts_enabled", default: false, null: false
    t.boolean "charges_enabled", default: false, null: false
    t.jsonb "capabilities", default: {}
    t.datetime "onboarding_completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["onboarding_status"], name: "index_stripe_connect_accounts_on_onboarding_status"
    t.index ["organization_id"], name: "index_stripe_connect_accounts_on_organization_id", unique: true
    t.index ["stripe_account_id"], name: "index_stripe_connect_accounts_on_stripe_account_id", unique: true
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "price_cents", default: 0, null: false
    t.string "currency", default: "USD", null: false
    t.string "billing_interval", default: "monthly", null: false
    t.jsonb "features", default: {}, null: false
    t.decimal "commission_rate", precision: 5, scale: 4, default: "0.16", null: false
    t.string "stripe_price_id"
    t.boolean "active", default: true, null: false
    t.integer "trial_days", default: 14
    t.integer "position", default: 0
    t.string "target_audience"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_subscription_plans_on_active"
    t.index ["slug"], name: "index_subscription_plans_on_slug", unique: true
    t.index ["target_audience"], name: "index_subscription_plans_on_target_audience"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "subscription_plan_id", null: false
    t.string "status", default: "trialing", null: false
    t.string "stripe_subscription_id"
    t.string "stripe_customer_id"
    t.datetime "trial_ends_at"
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.datetime "cancelled_at"
    t.string "cancel_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "status"], name: "index_subscriptions_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_subscriptions_on_organization_id"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
    t.index ["subscription_plan_id"], name: "index_subscriptions_on_subscription_plan_id"
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
    t.string "status", default: "active", null: false
    t.string "avatar_url"
    t.string "phone"
    t.datetime "onboarding_completed_at"
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token", unique: true
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "availability_blocks", "hotels"
  add_foreign_key "availability_blocks", "room_types"
  add_foreign_key "bookings", "clients"
  add_foreign_key "bookings", "experiences"
  add_foreign_key "bookings", "hotels", on_delete: :nullify
  add_foreign_key "bookings", "organizations"
  add_foreign_key "bookings", "retreats"
  add_foreign_key "bookings", "room_types"
  add_foreign_key "bookings", "rooms"
  add_foreign_key "clients", "organizations"
  add_foreign_key "experiences", "hotels"
  add_foreign_key "hotel_amenities", "hotels"
  add_foreign_key "hotel_images", "hotels"
  add_foreign_key "hotels", "organizations"
  add_foreign_key "inventory_blocks", "hotels"
  add_foreign_key "inventory_blocks", "organizations"
  add_foreign_key "inventory_blocks", "room_types"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "organizations", "organizations", column: "assigned_office_id"
  add_foreign_key "retreat_activities", "retreat_days"
  add_foreign_key "retreat_days", "retreats"
  add_foreign_key "retreat_facilitators", "retreats"
  add_foreign_key "retreat_images", "retreats"
  add_foreign_key "retreat_inclusions", "retreats"
  add_foreign_key "retreat_pricings", "retreats"
  add_foreign_key "retreat_pricings", "room_types"
  add_foreign_key "retreats", "hotels"
  add_foreign_key "retreats", "organizations", column: "created_by_organization_id"
  add_foreign_key "room_images", "room_types"
  add_foreign_key "room_rate_tiers", "room_types"
  add_foreign_key "room_types", "hotels"
  add_foreign_key "rooms", "hotels"
  add_foreign_key "rooms", "room_types"
  add_foreign_key "stripe_connect_accounts", "organizations"
  add_foreign_key "subscriptions", "organizations"
  add_foreign_key "subscriptions", "subscription_plans"
  add_foreign_key "users", "organizations"
end
