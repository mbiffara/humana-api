FactoryBot.define do
  factory :retreat do
    hotel
    association :created_by_organization, factory: [:organization, :hotel]
    sequence(:name) { |n| "Retreat #{n}" }
    retreat_type { "wellness" }
    duration_nights { 5 }
    starts_on { 30.days.from_now.to_date }
    ends_on { 35.days.from_now.to_date }
    capacity { 20 }
    language { "en" }
    status { "draft" }
    description { "A transformative retreat experience." }
    location { "Ibiza, Spain" }
    country { "Spain" }
    country_code { "ES" }
    currency { "USD" }
    commission_rate { 0.12 }
    created_by_type { "hotel" }

    trait :active do
      status { "active" }
      published_at { Time.current }
    end

    trait :upcoming do
      status { "upcoming" }
      published_at { Time.current }
    end

    trait :featured do
      featured { true }
    end
  end
end
