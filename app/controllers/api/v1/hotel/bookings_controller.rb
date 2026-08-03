module Api
  module V1
    module Hotel
      class BookingsController < BaseController
        before_action :set_booking, only: %i[show update confirm cancel]

        # GET /api/v1/hotel/bookings
        def index
          scope = hotel_bookings
                    .includes(:experience, :client, :room_type, :room, organization: [])
                    .order(created_at: :desc)
          scope = scope.where(status: params[:status]) if params[:status].present?
          scope = scope.where("bookings.starts_on >= ?", params[:from]) if params[:from].present?
          scope = scope.where("bookings.starts_on <= ?", params[:to]) if params[:to].present?
          scope = scope.where(room_type_id: params[:room_type_id]) if params[:room_type_id].present?

          if params[:q].present?
            q = "%#{params[:q]}%"
            scope = scope.left_joins(:client).where(
              "bookings.reference ILIKE :q OR clients.name ILIKE :q OR clients.email ILIKE :q",
              q: q
            )
          end

          render json: {
            bookings: paginate(scope).map { |b| serialize_hotel_booking(b) },
            meta: meta_for(scope),
            summary: build_summary
          }
        end

        # GET /api/v1/hotel/bookings/:id
        def show
          render json: { booking: serialize_hotel_booking(@booking) }
        end

        # PATCH /api/v1/hotel/bookings/:id
        def update
          @booking.update!(booking_params)
          render json: { booking: serialize_hotel_booking(@booking) }
        end

        # POST /api/v1/hotel/bookings/:id/confirm
        def confirm
          unless @booking.status == "inquiry"
            return render_unprocessable("Only inquiry bookings can be confirmed")
          end

          @booking.update!(status: "confirmed")
          render json: { booking: serialize_hotel_booking(@booking) }
        end

        # POST /api/v1/hotel/bookings/:id/cancel
        def cancel
          if @booking.status == "cancelled"
            return render_unprocessable("Booking is already cancelled")
          end

          @booking.update!(status: "cancelled")
          render json: { booking: serialize_hotel_booking(@booking) }
        end

        private

        def hotel_bookings
          Booking.joins(:experience).where(experiences: { hotel_id: current_hotel.id })
        end

        def set_booking
          @booking = hotel_bookings
                       .includes(:experience, :client, :room_type, :room, :organization)
                       .find(params[:id])
        end

        def booking_params
          params.require(:booking).permit(:notes, :room_type_id, :room_id)
        end

        def build_summary
          all = hotel_bookings
          active = all.active
          {
            total: all.count,
            confirmed: all.where(status: "confirmed").count,
            inquiry: all.where(status: "inquiry").count,
            completed: all.where(status: "completed").count,
            cancelled: all.where(status: "cancelled").count,
            revenue_cents: active.sum(:amount_cents),
            occupancy_rate: compute_occupancy
          }
        end

        def compute_occupancy
          total_rooms = current_hotel.room_types.sum(:total_rooms).to_i
          return 0 if total_rooms.zero?

          today = Date.current
          month_start = today.beginning_of_month
          month_end = today.end_of_month

          booked_room_nights = hotel_bookings.active
            .where("bookings.starts_on <= ? AND bookings.ends_on >= ?", month_end, month_start)
            .sum(:guests)

          days_in_month = (month_end - month_start).to_i + 1
          total_room_nights = total_rooms * days_in_month

          ((booked_room_nights.to_f / total_room_nights) * 100).round
        rescue StandardError
          0
        end

        # Extended booking serializer that includes agency info for the hotel view
        def serialize_hotel_booking(booking)
          base = ApiSerializers.booking(booking)
          base[:agency] = if booking.organization
                           {
                             id: booking.organization.id,
                             name: booking.organization.name,
                             city: booking.organization.city,
                             country: booking.organization.country
                           }
                         end
          base
        end
      end
    end
  end
end
