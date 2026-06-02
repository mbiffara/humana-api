# Properties operating as "centers of evolution" — the wellness hotels that
# host experiences. Each belongs to a hotel-kind organization.
class CreateHotels < ActiveRecord::Migration[8.0]
  def change
    create_table :hotels do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :city
      t.string :country
      t.string :country_code, limit: 2
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6
      t.boolean :certified, null: false, default: false
      t.string :wellness_standard # e.g. "Global Wellness Institute"
      t.text :description

      t.timestamps
    end

    add_index :hotels, :country_code
  end
end
