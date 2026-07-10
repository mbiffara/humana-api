# Singleton configuration table for platform-wide defaults. There should be
# exactly one row in this table, enforced by application logic.
class CreatePlatformSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :platform_settings do |t|
      t.string :platform_name, null: false, default: "HUMANA"
      t.string :support_email, null: false, default: "ops@humana.global"
      t.string :default_currency, limit: 3, null: false, default: "USD"
      t.string :default_language, limit: 2, null: false, default: "en"
      t.decimal :agency_commission_rate, precision: 5, scale: 4, null: false, default: "0.16"
      t.decimal :office_fee_rate, precision: 5, scale: 4, null: false, default: "0.02"
      t.decimal :hotel_net_rate, precision: 5, scale: 4, null: false, default: "0.82"
      t.string :terms_url
      t.string :privacy_url
      t.string :logo_url

      t.timestamps
    end
  end
end
