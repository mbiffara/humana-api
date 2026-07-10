FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Test User" }
    password { "humana1234" }
    role { "member" }
    status { "active" }
    locale { "en" }
    organization

    trait :admin do
      role { "admin" }
      association :organization, :admin
    end

    trait :owner do
      role { "owner" }
    end

    trait :pending do
      status { "pending" }
    end

    trait :suspended do
      status { "suspended" }
    end
  end
end
