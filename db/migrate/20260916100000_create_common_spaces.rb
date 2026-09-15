# Common spaces a hotel offers to retreat groups: halls, yoga and meditation
# rooms, terraces, gardens. Each one carries its capacity per layout, its
# size and floor, whether it can be booked exclusively, and its equipment.
class CreateCommonSpaces < ActiveRecord::Migration[8.0]
  def change
    create_table :common_spaces do |t|
      t.references :hotel, null: false, foreign_key: true
      t.string :name, null: false
      t.string :space_type, null: false
      t.string :space_type_other
      t.integer :capacity_seated
      t.integer :capacity_yoga
      t.integer :capacity_auditorium
      t.integer :capacity_banquet
      t.integer :capacity_workshop
      t.decimal :area_sqm, precision: 8, scale: 2
      t.string :floor_type
      t.string :floor_type_other
      t.boolean :exclusive_for_groups, null: false, default: false
      t.string :equipment, array: true, default: []
      t.string :equipment_other
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :common_spaces, [:hotel_id, :position]
  end
end
