# A single day within a retreat program. Contains ordered activities that
# compose the day's schedule (yoga, meals, workshops, free time, etc.).
class RetreatDay < ApplicationRecord
  belongs_to :retreat
  has_many :retreat_activities, -> { order(position: :asc) }, dependent: :destroy

  validates :day_number, presence: true, numericality: { greater_than: 0 },
            uniqueness: { scope: :retreat_id }

  scope :ordered, -> { order(day_number: :asc) }
end
