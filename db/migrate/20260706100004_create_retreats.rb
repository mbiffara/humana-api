# Full retreat definition with day-by-day program, facilitators, inclusions,
# per-room pricing, and media gallery. Unlike the lightweight Experience model,
# Retreat captures the complete program structure for the booking flow and
# marketplace presentation.
class CreateRetreats < ActiveRecord::Migration[8.0]
  def change
    create_table :retreats do |t|
      t.references :hotel, null: false, foreign_key: true
      t.references :created_by_organization, null: false, foreign_key: { to_table: :organizations }
      t.string :created_by_type, null: false, default: "hotel" # hotel | agency | office
      t.string :name, null: false
      t.string :slug, null: false
      t.string :retreat_type, null: false, default: "wellness" # wellness | spiritual | corporate | adventure | medical
      t.integer :duration_nights, null: false, default: 3
      t.date :starts_on
      t.date :ends_on
      t.integer :capacity
      t.string :language, null: false, default: "en"
      t.string :status, null: false, default: "draft" # draft | pending_review | active | upcoming | closed | cancelled
      t.text :description
      t.text :short_description
      t.string :location          # display string, e.g. "Ibiza, Spain"
      t.string :country
      t.string :country_code, limit: 2
      t.integer :min_price_cents, default: 0  # lowest room-type price (auto-computed)
      t.string :currency, null: false, default: "USD"
      t.decimal :commission_rate, precision: 5, scale: 4, null: false, default: "0.16"
      t.string :cover_image_url
      t.boolean :featured, null: false, default: false
      t.boolean :certified, null: false, default: false
      t.datetime :published_at

      t.timestamps
    end

    add_index :retreats, :slug, unique: true
    add_index :retreats, :retreat_type
    add_index :retreats, :status
    add_index :retreats, :country_code
    add_index :retreats, :featured
    add_index :retreats, [:hotel_id, :status]
  end
end
