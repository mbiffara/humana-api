# Room types declare how many beds the room has, alongside the existing bed
# type. Nullable: hotels that never filled it in keep reporting nothing.
class AddBedsCountToRoomTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :room_types, :beds_count, :integer
  end
end
