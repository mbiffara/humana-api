# Synchronize SubscriptionPlan records with Stripe Products + Prices.
# Idempotent — skips plans that already have a stripe_price_id.
#
# Usage:
#   rails stripe:sync_plans
namespace :stripe do
  desc "Create Stripe Products & Prices for subscription plans missing a stripe_price_id"
  task sync_plans: :environment do
    plans = SubscriptionPlan.where(stripe_price_id: [nil, ""])
                            .where("price_cents > 0")
                            .order(:position)

    if plans.empty?
      puts "All paid plans already have a stripe_price_id — nothing to sync."
      next
    end

    plans.each do |plan|
      puts "→ Syncing \"#{plan.name}\" ($#{plan.price_cents / 100})…"

      product = Stripe::Product.create(
        name: plan.name,
        metadata: { humana_plan_id: plan.id, audience: plan.target_audience }
      )

      price = Stripe::Price.create(
        product: product.id,
        unit_amount: plan.price_cents,
        currency: plan.currency.downcase,
        recurring: { interval: plan.billing_interval == "yearly" ? "year" : "month" }
      )

      plan.update!(stripe_price_id: price.id)
      puts "  ✓ stripe_price_id = #{price.id}"
    end

    puts "\nDone. #{plans.size} plan(s) synced."
  end
end
