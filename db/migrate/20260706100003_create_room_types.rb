# Room categories offered by a hotel. Each hotel can have multiple room types
# with different capacities and price points. Used in retreat pricing and
# accommodation assignment during the booking flow.
class CreateRoomTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :room_types do |t|
      t.references :hotel, null: false, foreign_key: true
      t.string :name, null: false
      t.string :category, null: false, default: "standard" # standard | superior | suite | villa
      t.integer :capacity, null: false, default: 2
      t.decimal :area_sqm, precision: 8, scale: 2
      t.integer :price_per_night_cents, null: false, default: 0
      t.string :currency, null: false, default: "USD"
      t.text :description
      t.string :image_url
      t.integer :total_rooms         # total available units
      t.integer :position, default: 0 # display order

      t.timestamps
    end

    add_index :room_types, :category
    add_index :room_types, [:hotel_id, :name], unique: true
  end
end
