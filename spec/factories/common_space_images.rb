FactoryBot.define do
  factory :common_space_image do
    common_space
    sequence(:image_url) { |n| "https://img.test/space-#{n}.jpg" }
    position { 0 }
    is_primary { false }
  end
end
