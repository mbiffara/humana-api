# Individual activities within a retreat day. Ordered by position to render
# the day's timeline in the booking flow and retreat detail page.
class CreateRetreatActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :retreat_activities do |t|
      t.references :retreat_day, null: false, foreign_key: true
      t.string :name, null: false
      t.string :time                # e.g. "07:00", "14:30"
      t.integer :duration_minutes   # optional
      t.integer :position, null: false, default: 0
      t.text :description
      t.string :category            # e.g. "yoga", "meditation", "meal", "workshop", "free_time"
      t.string :icon                # optional icon identifier

      t.timestamps
    end

    add_index :retreat_activities, [:retreat_day_id, :position]
  end
end
