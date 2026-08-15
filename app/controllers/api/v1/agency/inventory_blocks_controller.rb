# Agency inventory derived from real bookings.
# Groups the agency's lodging bookings by hotel + room_type and computes
# availability: bookings without a client assigned are "available rooms".
module Api
  module V1
    module Agency
      class InventoryBlocksController < BaseController
        def index
          scope = ::Booking.where(organization: current_organization)
                           .where.not(status: "cancelled")
                           .where.not(hotel_id: nil)      # only direct hotel bookings
                           .where.not(room_type_id: nil)   # must have a room type

          scope = scope.where(hotel_id: params[:hotel_id]) if params[:hotel_id].present?

          if params[:from].present? && params[:to].present?
            # Overlap: booking dates intersect the requested range
            scope = scope.where("starts_on <= ? AND ends_on >= ?", params[:to], params[:from])
          end

          bookings = scope.includes(:room_type, hotel: :hotel_images).to_a

          # Group by hotel + room_type
          grouped = {}
          bookings.each do |b|
            key = [b.hotel_id, b.room_type_id]
            (grouped[key] ||= []) << b
          end

          result = grouped.map do |(hotel_id, room_type_id), group|
            hotel = group.first.hotel
            rt    = group.first.room_type
            total     = group.size
            available = group.count { |b| b.client_id.nil? }

            {
              id: room_type_id,
              organization_id: current_organization.id,
              hotel_id: hotel_id,
              room_type_id: room_type_id,
              room_type: ApiSerializers.room_type(rt),
              hotel: ApiSerializers.hotel(hotel),
              total_rooms: total,
              available_rooms: available,
              starts_on: group.map(&:starts_on).min,
              ends_on: group.map(&:ends_on).max,
              cost_per_night_cents: rt.price_per_night_cents,
              cost_per_night: rt.price_per_night_cents / 100.0,
              currency: rt.currency || "USD",
              status: "active"
            }
          end

          render json: { inventory_blocks: result }
        end
      end
    end
  end
end
