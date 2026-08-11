class AddRetreatIdToBookings < ActiveRecord::Migration[8.0]
  def change
    add_reference :bookings, :retreat, null: true, foreign_key: true
  end
end
