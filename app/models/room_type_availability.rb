# Computes bookable units per day for a room type from its physical rooms,
# active bookings, and availability blocks. Nights are checkout-exclusive:
# a booking occupies starts_on up to (not including) ends_on. Used by the
# public availability endpoint and the booking-creation availability check.
class RoomTypeAvailability
  def initialize(room_type, from:, to:, exclude_booking_id: nil)
    @room_type = room_type
    @from = from
    @to = to
    @exclude_booking_id = exclude_booking_id
  end

  # Rooms currently in service. Room types without physical Room records
  # (inventory not tracked) report zero and callers should skip enforcement.
  def operational
    @operational ||= @room_type.rooms.where(status: "available").count
  end

  def tracked?
    operational.positive?
  end

  def days
    (@from..@to).map do |date|
      booked = bookings.count { |b| b.starts_on <= date && b.ends_on > date }
      blocked = blocks.select { |bl| bl.covers?(date) }.sum { |bl| bl.blocked_units(operational) }
      {
        date: date,
        available: (operational - booked - blocked).clamp(0, operational),
        total: operational
      }
    end
  end

  def min_available
    days.map { |d| d[:available] }.min || operational
  end

  private

  def bookings
    @bookings ||= begin
      scope = @room_type.bookings.active
                        .where.not(starts_on: nil).where.not(ends_on: nil)
                        .where("bookings.starts_on <= ? AND bookings.ends_on > ?", @to, @from)
      scope = scope.where.not(id: @exclude_booking_id) if @exclude_booking_id
      scope.to_a
    end
  end

  def blocks
    @blocks ||= @room_type.availability_blocks.overlapping(@from, @to).to_a
  end
end
