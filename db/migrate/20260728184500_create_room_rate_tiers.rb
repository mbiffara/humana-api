# Volume pricing for group bookings (HT-03e): a discounted nightly rate that
# applies when at least min_rooms of the room type are booked, optionally
# limited to a date range. The same tier size may repeat with different
# periods (seasonal group rates).
class CreateRoomRateTiers < ActiveRecord::Migration[8.0]
  def change
    create_table :room_rate_tiers do |t|
      t.references :room_type, null: false, foreign_key: true
      t.integer :min_rooms, null: false
      t.date :starts_on
      t.date :ends_on
      t.integer :price_per_night_cents, null: false

      t.timestamps
    end

    add_index :room_rate_tiers, %i[room_type_id min_rooms]
  end
end
