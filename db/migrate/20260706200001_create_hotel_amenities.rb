# Amenity chips for hotel onboarding step 3. Amenities are categorized
# (wellness, dining, facilities, recreation, services) and toggled per hotel.
class CreateHotelAmenities < ActiveRecord::Migration[8.0]
  def change
    create_table :hotel_amenities do |t|
      t.references :hotel, null: false, foreign_key: true
      t.string :name, null: false
      t.string :category, default: "general", null: false
      t.string :icon
      t.integer :position, default: 0
      t.boolean :featured, default: false, null: false

      t.timestamps
    end

    add_index :hotel_amenities, [:hotel_id, :name], unique: true
    add_index :hotel_amenities, :category
  end
end
