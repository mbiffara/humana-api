# Tracks room allotments purchased by an agency at a specific hotel.
# Each block represents N rooms of a given room type for a date range,
# at a negotiated cost per night. Available rooms are computed by
# subtracting rooms committed to active/pending retreats.
class InventoryBlock < ApplicationRecord
  STATUSES = %w[active expired cancelled].freeze

  belongs_to :organization
  belongs_to :hotel
  belongs_to :room_type

  validates :total_rooms, numericality: { greater_than: 0 }
  validates :cost_per_night_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :starts_on, :ends_on, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :ends_after_starts

  scope :active, -> { where(status: "active") }
  scope :for_hotel, ->(hotel_id) { where(hotel_id: hotel_id) }
  scope :covering_dates, ->(from, to) {
    where("starts_on <= ? AND ends_on >= ?", to, from)
  }

  def cost_per_night
    cost_per_night_cents / 100.0
  end

  # Rooms already committed to active/pending retreats by this org
  # for overlapping dates on the same room type.
  def committed_rooms
    RetreatPricing
      .joins(:retreat)
      .where(room_type_id: room_type_id)
      .where(retreats: {
        created_by_organization_id: organization_id,
        status: %w[draft pending_review active upcoming]
      })
      .where("retreats.starts_on <= ? AND retreats.ends_on >= ?", ends_on, starts_on)
      .count
  end

  def available_rooms
    [total_rooms - committed_rooms, 0].max
  end

  private

  def ends_after_starts
    return unless starts_on && ends_on
    errors.add(:ends_on, "must be after start date") if ends_on <= starts_on
  end
end
