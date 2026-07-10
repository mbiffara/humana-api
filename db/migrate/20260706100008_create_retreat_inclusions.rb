# Items included in the retreat price (e.g. "Full-board meals", "Airport transfer",
# "Spa access"). Displayed as a checklist on the retreat detail page.
class CreateRetreatInclusions < ActiveRecord::Migration[8.0]
  def change
    create_table :retreat_inclusions do |t|
      t.references :retreat, null: false, foreign_key: true
      t.string :name, null: false
      t.string :category, default: "general" # general | meal | transport | amenity | wellness
      t.string :icon                          # optional icon identifier
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :retreat_inclusions, [:retreat_id, :position]
  end
end
