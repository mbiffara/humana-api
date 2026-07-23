FactoryBot.define do
  factory :booking do
    organization
    experience
    guests { 2 }
    status { "confirmed" }
  end
end
