FactoryBot.define do
  factory :retreat_day do
    retreat
    sequence(:day_number) { |n| n }
    title { "Day #{day_number}" }
  end
end
