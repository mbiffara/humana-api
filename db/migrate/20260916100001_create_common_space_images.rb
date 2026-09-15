# Gallery photos for a common space. Mirrors room_images: ordered by position
# with a single primary that doubles as the space thumbnail.
class CreateCommonSpaceImages < ActiveRecord::Migration[8.0]
  def change
    create_table :common_space_images do |t|
      t.references :common_space, null: false, foreign_key: true
      t.string :image_url, null: false
      t.integer :position, null: false, default: 0
      t.boolean :is_primary, null: false, default: false
      t.string :alt_text

      t.timestamps
    end

    add_index :common_space_images, [:common_space_id, :position]
  end
end
