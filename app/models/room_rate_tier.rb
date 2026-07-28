# Volume pricing tier for a room type: a nightly rate that applies when a
# group books at least min_rooms rooms, optionally scoped to a date range.
# Purely informational until the booking engine consumes tiered pricing.
class RoomRateTier < ApplicationRecord
  belongs_to :room_type

  validates :min_rooms, numericality: { only_integer: true, greater_than: 1 }
  validates :price_per_night_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :ends_on_after_starts_on

  scope :ordered, -> { order(:min_rooms, :starts_on, :id) }

  def price_per_night
    price_per_night_cents / 100.0
  end

  private

  def ends_on_after_starts_on
    return if starts_on.nil? || ends_on.nil?

    errors.add(:ends_on, "must be on or after starts_on") if ends_on < starts_on
  end
end
