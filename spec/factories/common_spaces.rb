FactoryBot.define do
  factory :common_space do
    hotel
    sequence(:name) { |n| "Common Space #{n}" }
    space_type { "salon" }
  end
end
