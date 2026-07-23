FactoryBot.define do
  factory :availability_block do
    room_type
    hotel { room_type.hotel }
    starts_on { Date.new(2026, 11, 1) }
    ends_on { Date.new(2026, 11, 30) }
    units { nil }
  end
end
