# Retreats, masterclasses and corporate programs hosted at a hotel. These are
# what agencies discover and book on behalf of their clients.
class CreateExperiences < ActiveRecord::Migration[8.0]
  def change
    create_table :experiences do |t|
      t.references :hotel, null: false, foreign_key: true
      t.string :slug, null: false
      t.string :kind, null: false, default: "retreat" # retreat | masterclass | corporate
      t.string :title, null: false
      t.text :description
      t.string :location # display string, e.g. "Ibiza · Spain"
      t.string :country
      t.string :country_code, limit: 2
      t.date :starts_on
      t.date :ends_on
      t.integer :price_cents, null: false, default: 0
      t.string :currency, null: false, default: "USD"
      t.decimal :commission_rate, precision: 5, scale: 4, null: false, default: "0.0" # 0.12 = 12%
      t.integer :capacity
      t.string :image_url
      t.string :status, null: false, default: "draft" # draft | active | upcoming | closed

      t.timestamps
    end

    add_index :experiences, :slug, unique: true
    add_index :experiences, :kind
    add_index :experiences, :status
    add_index :experiences, :country_code
  end
end
