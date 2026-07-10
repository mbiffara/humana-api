# Property-level gallery image. Used in hotel onboarding step 4 (Property Photos)
# and hotel detail/listing pages. Categorized by area (exterior, lobby, spa,
# restaurant, room, pool, garden, general).
class HotelImage < ApplicationRecord
  CATEGORIES = %w[
    exterior lobby spa restaurant room pool
    garden common_area general
  ].freeze

  belongs_to :hotel

  validates :image_url, presence: true
  validates :category, inclusion: { in: CATEGORIES }

  scope :ordered, -> { order(position: :asc) }
  scope :covers, -> { where(is_cover: true) }
  scope :by_category, ->(c) { c.present? ? where(category: c) : all }
end
