FactoryBot.define do
  factory :room_type do
    hotel
    sequence(:name) { |n| "Room Type #{n}" }
    category { "standard" }
    capacity { 2 }
    area_sqm { 30.0 }
    price_per_night_cents { 15000 }
    currency { "USD" }

    trait :suite do
      category { "suite" }
      capacity { 2 }
      price_per_night_cents { 35000 }
    end

    trait :villa do
      category { "villa" }
      capacity { 4 }
      price_per_night_cents { 60000 }
    end
  end
end
