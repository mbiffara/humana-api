class AddRoomRefsToBookings < ActiveRecord::Migration[8.0]
  def change
    add_reference :bookings, :room_type, null: true, foreign_key: true
    add_reference :bookings, :room, null: true, foreign_key: true
  end
end
