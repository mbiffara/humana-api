# Property profile fields for the hotel onboarding form (LOG-131..LOG-136):
# location detail, property type, environments, pet policy and group size.
# Every column is nullable (or has a default) so existing rows stay valid.
# `stars` is intentionally left in place — it stops being used by the API but
# the historical values are kept.
class AddPropertyProfileFieldsToHotels < ActiveRecord::Migration[8.0]
  def change
    change_table :hotels, bulk: true do |t|
      # Location detail
      t.string  :state_region
      t.string  :instagram
      t.string  :nearest_airport
      t.decimal :airport_distance_km, precision: 6, scale: 1
      t.integer :airport_time_min
      t.string  :airport_transfer
      t.text    :airport_transfer_notes
      t.decimal :distance_to_center_km, precision: 6, scale: 1

      # Property type
      t.string :property_type
      t.string :property_type_other

      # Environments (multi-select)
      t.string :environments, array: true, default: [], null: false

      # Pet policy
      t.boolean :pet_friendly
      t.boolean :pet_dogs
      t.boolean :pet_cats
      t.boolean :pet_size_restriction
      t.string  :pet_size_restriction_notes
      t.boolean :pet_extra_cost
      t.string  :pet_extra_cost_notes
      t.boolean :pet_common_areas
      t.boolean :pet_specific_rooms

      # Group size
      t.integer :group_min_guests
      t.integer :group_max_guests
    end
  end
end
