class CreateInventoryBlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_blocks do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :hotel, null: false, foreign_key: true
      t.references :room_type, null: false, foreign_key: true
      t.integer    :total_rooms, null: false
      t.date       :starts_on, null: false
      t.date       :ends_on, null: false
      t.integer    :cost_per_night_cents, null: false
      t.string     :currency, default: "USD", null: false
      t.string     :status, default: "active", null: false
      t.timestamps
    end

    add_index :inventory_blocks, [:organization_id, :hotel_id, :room_type_id],
              name: "idx_inv_blocks_org_hotel_rt"
  end
end
