class AddAssignedOfficeIdToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_reference :organizations, :assigned_office, foreign_key: { to_table: :organizations }, null: true
  end
end
