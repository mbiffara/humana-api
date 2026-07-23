FactoryBot.define do
  factory :room do
    room_type
    hotel { room_type.hotel }
    sequence(:number) { |n| "Room #{n}" }
    status { "available" }
    auto_generated { false }
  end
end
