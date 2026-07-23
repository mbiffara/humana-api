# Availability calendar for the hotel workspace. For each room type it
# returns the room inventory and, per day, how many rooms are booked and how
# many remain available. Occupancy comes from active bookings attributed to a
# room type; bookings without one are surfaced separately so the hotel knows
# the per-type counts are not the whole story. Nights are checkout-exclusive:
# a booking occupies starts_on up to (not including) ends_on.
module Api
  module V1
    module Hotel
      class CalendarController < BaseController
        MAX_RANGE_DAYS = 92

        # GET /api/v1/hotel/calendar?from=2026-08-01&to=2026-08-31
        def index
          from = parse_date(params[:from]) || Date.current
          to = parse_date(params[:to]) || from + 29
          return render_bad_request("`to` must be on or after `from`") if to < from

          to = from + (MAX_RANGE_DAYS - 1) if (to - from).to_i >= MAX_RANGE_DAYS
          days = (from..to).to_a

          bookings = overlapping_bookings(from, to)
          typed = bookings.reject { |b| b.room_type_id.nil? }.group_by(&:room_type_id)
          unassigned = bookings.select { |b| b.room_type_id.nil? }
          blocks = current_hotel.availability_blocks.overlapping(from, to).group_by(&:room_type_id)

          render json: {
            from: from,
            to: to,
            room_types: current_hotel.room_types.includes(:rooms).ordered.map do |rt|
              calendar_entry(rt, typed[rt.id] || [], blocks[rt.id] || [], days)
            end,
            unassigned_bookings: days.map { |d| { date: d, count: unassigned.count { |b| occupies?(b, d) } } }
          }
        end

        private

        def overlapping_bookings(from, to)
          ::Booking.active
                   .joins(:experience)
                   .where(experiences: { hotel_id: current_hotel.id })
                   .where.not(starts_on: nil)
                   .where.not(ends_on: nil)
                   .where("bookings.starts_on <= ? AND bookings.ends_on >= ?", to, from)
                   .to_a
        end

        def calendar_entry(room_type, bookings, blocks, days)
          rooms = room_type.rooms
          operational = rooms.count { |r| r.status == "available" }

          {
            room_type: ApiSerializers.room_type(room_type),
            rooms_total: rooms.size,
            rooms_operational: operational,
            days: days.map do |d|
              booked = bookings.count { |b| occupies?(b, d) }
              blocked = blocks.select { |bl| bl.covers?(d) }
                              .sum { |bl| bl.blocked_units(operational) }
                              .clamp(0, operational)
              { date: d, booked: booked, blocked: blocked,
                available: [operational - blocked - booked, 0].max }
            end
          }
        end

        # Checkout-exclusive, except same-day bookings which occupy that night.
        def occupies?(booking, date)
          return date == booking.starts_on if booking.ends_on == booking.starts_on

          booking.starts_on <= date && booking.ends_on > date
        end

        def parse_date(value)
          return nil if value.blank?

          Date.iso8601(value.to_s)
        rescue ArgumentError, TypeError
          nil
        end
      end
    end
  end
end
