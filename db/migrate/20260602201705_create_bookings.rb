# An agency's reservation of an experience for one of its clients, carrying the
# transparent commission that HUMANA settles back to the agency.
class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.references :organization, null: false, foreign_key: true # booking agency
      t.references :experience, null: false, foreign_key: true
      t.references :client, foreign_key: true
      t.string :reference, null: false
      t.integer :guests, null: false, default: 1
      t.date :starts_on
      t.date :ends_on
      t.string :status, null: false, default: "inquiry" # inquiry | confirmed | cancelled | completed
      t.integer :amount_cents, null: false, default: 0
      t.string :currency, null: false, default: "USD"
      t.integer :commission_cents, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :bookings, :reference, unique: true
    add_index :bookings, :status
  end
end
