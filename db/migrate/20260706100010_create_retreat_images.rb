# Gallery images for a retreat. Ordered by position for the carousel display.
class CreateRetreatImages < ActiveRecord::Migration[8.0]
  def change
    create_table :retreat_images do |t|
      t.references :retreat, null: false, foreign_key: true
      t.string :image_url, null: false
      t.integer :position, null: false, default: 0
      t.string :alt_text
      t.boolean :is_cover, null: false, default: false

      t.timestamps
    end

    add_index :retreat_images, [:retreat_id, :position]
    add_index :retreat_images, [:retreat_id, :is_cover]
  end
end
