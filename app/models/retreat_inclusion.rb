# Item included in the retreat price. Displayed as a checklist on the
# retreat detail page (e.g. "Full-board meals", "Airport transfer", "Spa access").
class RetreatInclusion < ApplicationRecord
  CATEGORIES = %w[general meal transport amenity wellness activity equipment].freeze

  belongs_to :retreat

  validates :name, presence: true
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true

  scope :ordered, -> { order(position: :asc) }
end
