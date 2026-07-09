# Days within a retreat program. Each day contains ordered activities that
# define the retreat's daily schedule.
class CreateRetreatDays < ActiveRecord::Migration[8.0]
  def change
    create_table :retreat_days do |t|
      t.references :retreat, null: false, foreign_key: true
      t.integer :day_number, null: false  # 1-based
      t.string :title                      # e.g. "Arrival & Integration"
      t.text :description

      t.timestamps
    end

    add_index :retreat_days, [:retreat_id, :day_number], unique: true
  end
end
