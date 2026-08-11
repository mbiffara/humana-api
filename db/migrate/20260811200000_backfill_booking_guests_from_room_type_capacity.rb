class BackfillBookingGuestsFromRoomTypeCapacity < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE bookings
      SET guests = room_types.capacity
      FROM room_types
      WHERE bookings.room_type_id = room_types.id
        AND bookings.guests = 1
        AND room_types.capacity > 1
    SQL
  end

  def down
    # No-op: cannot reliably restore original values
  end
end
