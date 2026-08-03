class AddBankDetailsToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :bank_account_holder, :string
    add_column :organizations, :bank_iban, :string
    add_column :organizations, :bank_swift, :string
    add_column :organizations, :bank_currency, :string, default: "USD"
    add_column :organizations, :bank_country, :string
    add_column :organizations, :bank_status, :string, default: "pending"
  end
end
