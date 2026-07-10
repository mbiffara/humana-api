FactoryBot.define do
  factory :retreat_activity do
    retreat_day
    sequence(:name) { |n| "Activity #{n}" }
    time { "09:00" }
    position { 0 }
    category { "yoga" }
  end
end
