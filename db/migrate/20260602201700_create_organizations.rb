# Member businesses on the HUMANA network: hotels, tourism agencies and the
# internal admin operator. Access to the platform is restricted to these.
class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :kind, null: false, default: "agency" # hotel | agency | admin
      t.string :status, null: false, default: "pending" # pending | verified | suspended
      t.string :city
      t.string :country
      t.string :country_code, limit: 2
      t.string :contact_email
      t.string :website

      t.timestamps
    end

    add_index :organizations, :kind
    add_index :organizations, :status
  end
end
