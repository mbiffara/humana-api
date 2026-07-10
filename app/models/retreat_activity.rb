# Individual activity within a retreat day's schedule. Rendered as a timeline
# on the retreat detail page with time, name, and optional description.
class RetreatActivity < ApplicationRecord
  CATEGORIES = %w[yoga meditation meal workshop free_time ceremony
                   breathwork excursion spa check_in check_out other].freeze

  belongs_to :retreat_day

  validates :name, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true

  scope :ordered, -> { order(position: :asc) }
end
