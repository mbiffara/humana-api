class CreateAvailabilityBlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :availability_blocks do |t|
      t.references :hotel, null: false, foreign_key: true
      t.references :room_type, null: false, foreign_key: true
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.integer :units
      t.string :reason

      t.timestamps
    end

    add_index :availability_blocks, %i[room_type_id starts_on ends_on],
              name: "index_availability_blocks_on_room_type_and_range"
  end
end
