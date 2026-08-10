FactoryBot.define do
  factory :experience do
    hotel
    sequence(:title) { |n| "Wellness Experience #{n}" }
    kind { "wellness" }
    status { "active" }
    price_cents { 100_000 }
    commission_rate { 0.16 }
    currency { "USD" }
    country { "Spain" }
    country_code { "ES" }
    starts_on { Date.current }
    ends_on { Date.current + 5 }
  end
end
