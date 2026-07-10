# Enabled countries for the HUMANA platform. Used for organization assignment,
# office mapping, and filtering across the marketplace.
class CreateCountries < ActiveRecord::Migration[8.0]
  def change
    create_table :countries do |t|
      t.string :name, null: false
      t.string :code, limit: 2, null: false
      t.string :flag_emoji
      t.string :status, null: false, default: "active" # active | inactive
      t.boolean :enabled, null: false, default: true
      t.string :region          # e.g. "LATAM", "Europe", "APAC"
      t.string :currency_code, limit: 3  # ISO 4217
      t.string :timezone        # IANA timezone

      t.timestamps
    end

    add_index :countries, :code, unique: true
    add_index :countries, :status
    add_index :countries, :enabled
    add_index :countries, :region
  end
end
