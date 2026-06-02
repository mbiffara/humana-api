# End customers managed by an agency. Bookings are placed on their behalf.
class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.references :organization, null: false, foreign_key: true # the agency
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.text :notes

      t.timestamps
    end

    add_index :clients, [:organization_id, :email]
  end
end
