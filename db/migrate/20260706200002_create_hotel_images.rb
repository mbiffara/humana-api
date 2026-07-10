# Property-level gallery images for hotel onboarding step 4.
# Distinct from retreat_images which are per-retreat.
class CreateHotelImages < ActiveRecord::Migration[8.0]
  def change
    create_table :hotel_images do |t|
      t.references :hotel, null: false, foreign_key: true
      t.string :image_url, null: false
      t.string :category, default: "general", null: false
      t.integer :position, default: 0, null: false
      t.string :alt_text
      t.boolean :is_cover, default: false, null: false

      t.timestamps
    end

    add_index :hotel_images, [:hotel_id, :position]
    add_index :hotel_images, [:hotel_id, :is_cover]
    add_index :hotel_images, :category
  end
end
