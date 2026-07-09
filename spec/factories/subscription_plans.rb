FactoryBot.define do
  factory :subscription_plan do
    sequence(:name) { |n| "Plan #{n}" }
    price_cents { 9900 }
    currency { "USD" }
    billing_interval { "monthly" }
    commission_rate { 0.14 }
    active { true }
    trial_days { 14 }
    target_audience { "agency" }
    features { { max_bookings: -1 } }
  end
end
