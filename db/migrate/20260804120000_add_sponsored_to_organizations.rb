class AddSponsoredToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :sponsored, :boolean, default: false, null: false
  end
end
