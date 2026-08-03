class MakeBookingExperienceOptional < ActiveRecord::Migration[8.0]
  def change
    change_column_null :bookings, :experience_id, true

    add_column :bookings, :hotel_id, :bigint
    add_index :bookings, :hotel_id
    add_foreign_key :bookings, :hotels, on_delete: :nullify
  end
end
