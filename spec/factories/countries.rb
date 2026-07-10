FactoryBot.define do
  factory :country do
    sequence(:name) { |n| "Country #{n}" }
    sequence(:code) { |n| ("AA".."ZZ").to_a[n % 676] }
    flag_emoji { "\u{1F3F3}" }
    status { "active" }
    enabled { true }
    region { "Europe" }
    currency_code { "EUR" }
    timezone { "Europe/Madrid" }
  end
end
