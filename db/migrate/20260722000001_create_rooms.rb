class CreateRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms do |t|
      t.references :hotel, null: false, foreign_key: true
      t.references :room_type, null: false, foreign_key: true
      t.string :number, null: false
      t.string :status, null: false, default: "available"
      t.boolean :auto_generated, null: false, default: false
      t.text :notes

      t.timestamps
    end

    add_index :rooms, "hotel_id, lower(number)", unique: true, name: "index_rooms_on_hotel_id_and_lower_number"
    add_index :rooms, %i[room_type_id status]
  end
end
