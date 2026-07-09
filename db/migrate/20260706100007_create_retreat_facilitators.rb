# Expert practitioners who lead retreat programs. Can be assigned to multiple
# retreats and have different roles per assignment.
class CreateRetreatFacilitators < ActiveRecord::Migration[8.0]
  def change
    create_table :retreat_facilitators do |t|
      t.references :retreat, null: false, foreign_key: true
      t.string :name, null: false
      t.string :role, null: false, default: "lead" # lead | assistant | guest
      t.string :specialty           # e.g. "Breathwork", "Yoga", "Nutrition"
      t.string :avatar_url
      t.text :bio
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :retreat_facilitators, [:retreat_id, :role]
  end
end
