# Gallery image for a retreat. Ordered by position for carousel display.
# One image may be flagged as the cover for list/card views.
class RetreatImage < ApplicationRecord
  belongs_to :retreat

  validates :image_url, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(position: :asc) }
  scope :covers, -> { where(is_cover: true) }
end
