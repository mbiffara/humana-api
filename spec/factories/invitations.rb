FactoryBot.define do
  factory :invitation do
    sequence(:email) { |n| "invited#{n}@example.com" }
    role { "member" }
    organization
    association :invited_by, factory: :user
  end
end
