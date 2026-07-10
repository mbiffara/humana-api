# Room category within a hotel. Hotels may offer multiple room types (standard,
# superior, suite, villa) each with different capacity and nightly rates.
# Referenced by RetreatPricing for per-guest retreat pricing by room category.
class RoomType < ApplicationRecord
  CATEGORIES = %w[standard superior suite villa penthouse bungalow].freeze

  BED_TYPES = %w[single double queen king twin bunk sofa_bed].freeze

  belongs_to :hotel
  has_many :retreat_pricings, dependent: :destroy
  has_many :room_images, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :hotel_id }
  validates :category, inclusion: { in: CATEGORIES }
  validates :capacity, numericality: { greater_than: 0 }
  validates :price_per_night_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :bed_type, inclusion: { in: BED_TYPES }, allow_nil: true

  scope :by_category, ->(c) { c.present? ? where(category: c) : all }
  scope :ordered, -> { order(position: :asc, price_per_night_cents: :asc) }

  def price_per_night
    price_per_night_cents / 100.0
  end
end
