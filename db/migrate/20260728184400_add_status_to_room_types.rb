# Room types gain a lifecycle status for the HT-03 management screens:
# active (bookable), draft (being configured), inactive (retired from sale).
class AddStatusToRoomTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :room_types, :status, :string, null: false, default: "active" # active | draft | inactive
    add_index :room_types, :status
  end
end
