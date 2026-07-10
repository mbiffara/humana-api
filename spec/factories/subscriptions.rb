FactoryBot.define do
  factory :subscription do
    organization
    subscription_plan
    status { "active" }
    current_period_start { Time.current }
    current_period_end { 30.days.from_now }

    trait :trialing do
      status { "trialing" }
      trial_ends_at { 14.days.from_now }
    end

    trait :cancelled do
      status { "cancelled" }
      cancelled_at { Time.current }
    end
  end
end
