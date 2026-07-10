# Active subscriptions linking organizations to their chosen plan. Tracks
# Stripe subscription lifecycle and billing status.
class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :subscription_plan, null: false, foreign_key: true
      t.string :status, null: false, default: "trialing" # trialing | active | past_due | cancelled | expired
      t.string :stripe_subscription_id
      t.string :stripe_customer_id
      t.datetime :trial_ends_at
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :cancelled_at
      t.string :cancel_reason

      t.timestamps
    end

    add_index :subscriptions, :status
    add_index :subscriptions, :stripe_subscription_id, unique: true
    add_index :subscriptions, [:organization_id, :status]
  end
end
