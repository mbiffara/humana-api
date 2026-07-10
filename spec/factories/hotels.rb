FactoryBot.define do
  factory :hotel do
    association :organization, factory: [:organization, :hotel]
    sequence(:name) { |n| "Hotel #{n}" }
    city { "Ibiza" }
    country { "Spain" }
    country_code { "ES" }
    latitude { 38.9067 }
    longitude { 1.4206 }
    certified { true }
    wellness_standard { "Global Wellness Institute" }
  end
end
