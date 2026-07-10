# Per-room-type pricing for a retreat. Different room categories within the
# same retreat have different per-guest rates.
class CreateRetreatPricings < ActiveRecord::Migration[8.0]
  def change
    create_table :retreat_pricings do |t|
      t.references :retreat, null: false, foreign_key: true
      t.references :room_type, null: false, foreign_key: true
      t.integer :price_per_guest_cents, null: false, default: 0
      t.string :currency, null: false, default: "USD"
      t.string :occupancy_label         # e.g. "Single", "Double", "Triple"
      t.integer :max_guests, default: 2

      t.timestamps
    end

    add_index :retreat_pricings, [:retreat_id, :room_type_id], unique: true
  end
end
