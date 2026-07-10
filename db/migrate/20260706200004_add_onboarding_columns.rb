# Columns needed for onboarding flows identified from Paper designs:
# - organizations: legal_name, phone, primary_contact (agency onboarding AG-00c)
# - hotels: address, postal_code, phone, stars, check_in_time, check_out_time,
#           total_rooms (property identity HT-01a)
# - room_types: bed_type, amenities (room inventory HT-01b)
# - users: onboarding_completed_at, avatar_url (track wizard completion)
class AddOnboardingColumns < ActiveRecord::Migration[8.0]
  def change
    # Organization onboarding fields (agency profile)
    change_table :organizations, bulk: true do |t|
      t.string :legal_name
      t.string :phone
      t.string :primary_contact
      t.string :tax_id
      t.text :description
      t.string :logo_url
      t.string :specialties, array: true, default: []
      t.datetime :onboarding_completed_at
    end

    # Hotel property identity fields
    change_table :hotels, bulk: true do |t|
      t.string :address
      t.string :postal_code
      t.string :phone
      t.integer :stars
      t.string :check_in_time, default: "15:00"
      t.string :check_out_time, default: "11:00"
      t.integer :total_rooms
      t.string :logo_url
      t.string :website
      t.string :contact_email
      t.datetime :onboarding_completed_at
    end

    # Room type bed config
    change_table :room_types, bulk: true do |t|
      t.string :bed_type
      t.string :amenities, array: true, default: []
      t.string :view_type
    end

    # User onboarding tracking
    change_table :users, bulk: true do |t|
      t.string :avatar_url
      t.string :phone
      t.datetime :onboarding_completed_at
    end
  end
end
