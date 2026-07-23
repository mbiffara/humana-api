# A date-ranged closure of room inventory: "N units of this room type are
# unavailable from starts_on to ends_on (inclusive)". units: nil closes the
# whole room type. Everything outside a block is available by default — blocks
# only ever subtract. Covers seasonal closures, renovations, and limiting the
# allotment offered to the HUMANA network.
class AvailabilityBlock < ApplicationRecord
  belongs_to :hotel
  belongs_to :room_type

  validates :starts_on, :ends_on, presence: true
  validates :units, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :ends_on_after_starts_on
  validate :room_type_belongs_to_hotel

  scope :overlapping, ->(from, to) { where("starts_on <= ? AND ends_on >= ?", to, from) }
  scope :by_room_type, ->(id) { id.present? ? where(room_type_id: id) : all }
  scope :ordered, -> { order(:starts_on, :id) }

  def covers?(date)
    starts_on <= date && ends_on >= date
  end

  # Units this block removes from a room type with `operational` open rooms.
  def blocked_units(operational)
    [units || operational, operational].min
  end

  private

  def ends_on_after_starts_on
    return if starts_on.nil? || ends_on.nil?

    errors.add(:ends_on, "must be on or after starts_on") if ends_on < starts_on
  end

  def room_type_belongs_to_hotel
    return if room_type.nil? || hotel.nil?

    errors.add(:room_type, "must belong to the same hotel") if room_type.hotel_id != hotel_id
  end
end
