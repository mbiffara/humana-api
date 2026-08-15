class AddAllocatedRoomsToRetreatPricings < ActiveRecord::Migration[8.0]
  def change
    add_column :retreat_pricings, :allocated_rooms, :integer
  end
end
