# Per-room-type gallery images. Each room type can have multiple photos
# showing different angles, amenities, and views.
class CreateRoomImages < ActiveRecord::Migration[8.0]
  def change
    create_table :room_images do |t|
      t.references :room_type, null: false, foreign_key: true
      t.string :image_url, null: false
      t.integer :position, default: 0, null: false
      t.string :alt_text
      t.boolean :is_primary, default: false, null: false

      t.timestamps
    end

    add_index :room_images, [:room_type_id, :position]
  end
end
