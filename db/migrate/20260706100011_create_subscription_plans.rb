# Subscription tiers for the HUMANA platform. Each plan defines pricing,
# features, and the agency commission rate applied to bookings.
class CreateSubscriptionPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_plans do |t|
      t.string :name, null: false              # e.g. "Starter", "Professional", "Enterprise"
      t.string :slug, null: false
      t.integer :price_cents, null: false, default: 0
      t.string :currency, null: false, default: "USD"
      t.string :billing_interval, null: false, default: "monthly" # monthly | yearly
      t.jsonb :features, null: false, default: {}     # feature flags and limits
      t.decimal :commission_rate, precision: 5, scale: 4, null: false, default: "0.16"
      t.string :stripe_price_id               # Stripe Price ID for checkout
      t.boolean :active, null: false, default: true
      t.integer :trial_days, default: 14
      t.integer :position, default: 0          # display order
      t.string :target_audience                # "agency" | "hotel" — who this plan is for

      t.timestamps
    end

    add_index :subscription_plans, :slug, unique: true
    add_index :subscription_plans, :active
    add_index :subscription_plans, :target_audience
  end
end
