FactoryBot.define do
  factory :organization do
    name { "Test Agency" }
    kind { "agency" }
    status { "verified" }
    city { "Madrid" }
    country { "Spain" }
    country_code { "ES" }
    contact_email { "test@example.com" }

    trait :admin do
      name { "HUMANA Global" }
      kind { "admin" }
    end

    trait :hotel do
      name { "Test Hotel" }
      kind { "hotel" }
    end

    trait :office do
      name { "HUMANA LATAM" }
      kind { "office" }
    end

    trait :pending do
      status { "pending" }
    end
  end
end
