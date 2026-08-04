class CollapseMaintenanceRoomStatus < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE rooms SET status = 'out_of_service' WHERE status = 'maintenance'"
  end

  def down
    # maintenance rooms were folded into out_of_service; nothing to restore
  end
end
