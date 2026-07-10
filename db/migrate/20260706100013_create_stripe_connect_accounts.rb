# Stripe Connect accounts for hotel organizations receiving payouts. Tracks
# onboarding status and monthly recurring revenue for platform analytics.
class CreateStripeConnectAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :stripe_connect_accounts do |t|
      t.references :organization, null: false, foreign_key: true, index: false
      t.string :stripe_account_id, null: false
      t.string :onboarding_status, null: false, default: "pending" # pending | in_progress | complete | restricted
      t.integer :mrr_cents, default: 0                              # monthly recurring revenue snapshot
      t.string :currency, null: false, default: "USD"
      t.boolean :payouts_enabled, null: false, default: false
      t.boolean :charges_enabled, null: false, default: false
      t.jsonb :capabilities, default: {}
      t.datetime :onboarding_completed_at

      t.timestamps
    end

    add_index :stripe_connect_accounts, :stripe_account_id, unique: true
    add_index :stripe_connect_accounts, :onboarding_status
    add_index :stripe_connect_accounts, [:organization_id], unique: true
  end
end
