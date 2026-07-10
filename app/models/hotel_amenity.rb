# Amenity offered by a hotel property. Categorized for display in the
# onboarding wizard (step 3) and hotel detail pages. Each amenity is unique
# per hotel — duplicates prevented at the DB level.
class HotelAmenity < ApplicationRecord
  CATEGORIES = %w[
    wellness dining facilities recreation services
    accessibility sustainability general
  ].freeze

  belongs_to :hotel

  validates :name, presence: true, uniqueness: { scope: :hotel_id }
  validates :category, inclusion: { in: CATEGORIES }

  scope :by_category, ->(c) { c.present? ? where(category: c) : all }
  scope :featured, -> { where(featured: true) }
  scope :ordered, -> { order(position: :asc, name: :asc) }
end
