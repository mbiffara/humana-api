module Api
  module V1
    module Public
      # Public list of network hotels. No authentication required.
      class HotelsController < Api::V1::PublicController
        # GET /api/v1/public/hotels?country=ES&q=ibiza&certified=true
        def index
          scope = ::Hotel.in_enabled_country
                       .in_country(params[:country])
                       .search(params[:q])
                       .order(:name)
          scope = scope.certified if ActiveModel::Type::Boolean.new.cast(params[:certified])

          render json: {
            hotels: paginate(scope).map { |h| ApiSerializers.hotel(h) },
            meta: meta_for(scope)
          }
        end

        # GET /api/v1/public/hotels/:id
        def show
          hotel = ::Hotel.find(params[:id])
          render json: { hotel: ApiSerializers.hotel(hotel) }
        end

        MAX_AVAILABILITY_RANGE_DAYS = 92

        # GET /api/v1/public/hotels/:id/availability?from=2026-08-01&to=2026-08-31
        # Real per-day availability per active room type, so agencies can see
        # what is actually bookable before creating a reservation.
        def availability
          hotel = ::Hotel.find(params[:id])
          from = parse_date(params[:from]) || Date.current
          to = parse_date(params[:to]) || from + 29
          return render_bad_request("`to` must be on or after `from`") if to < from

          to = from + (MAX_AVAILABILITY_RANGE_DAYS - 1) if (to - from).to_i >= MAX_AVAILABILITY_RANGE_DAYS

          render json: {
            hotel_id: hotel.id,
            from: from,
            to: to,
            room_types: hotel.room_types.by_status("active").ordered.map do |room_type|
              {
                room_type: ApiSerializers.room_type(room_type),
                days: RoomTypeAvailability.new(room_type, from: from, to: to).days
              }
            end
          }
        end

        private

        def parse_date(value)
          Date.iso8601(value.to_s)
        rescue Date::Error
          nil
        end
      end
    end
  end
end
