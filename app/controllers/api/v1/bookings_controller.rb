module Api
  module V1
    # Reservations placed by an agency on behalf of its clients, including the
    # commission HUMANA settles back to the agency.
    class BookingsController < BaseController
      before_action :require_agency!
      before_action :set_booking, only: %i[show update]

      # GET /api/v1/bookings?status=confirmed
      def index
        scope = current_organization.bookings
                                    .includes(:experience, :client)
                                    .order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?

        render json: {
          bookings: paginate(scope).map { |b| ApiSerializers.booking(b) },
          meta: meta_for(scope),
          summary: summary(scope)
        }
      end

      # GET /api/v1/bookings/:id
      def show
        render json: { booking: ApiSerializers.booking(@booking) }
      end

      # POST /api/v1/bookings
      def create
        booking = current_organization.bookings.new(booking_params)
        booking.save!
        render json: { booking: ApiSerializers.booking(booking) }, status: :created
      end

      # PATCH/PUT /api/v1/bookings/:id  (update status / guests / notes)
      def update
        @booking.update!(update_params)
        render json: { booking: ApiSerializers.booking(@booking) }
      end

      private

      def set_booking
        @booking = current_organization.bookings.includes(:experience, :client).find(params[:id])
      end

      def booking_params
        params.require(:booking).permit(:experience_id, :client_id, :guests, :notes)
      end

      def update_params
        params.require(:booking).permit(:status, :guests, :notes)
      end

      # Commission and volume totals for the agency's commissions view.
      def summary(scope)
        active = scope.active
        {
          total: scope.count,
          confirmed: scope.where(status: "confirmed").count,
          commission_cents: active.sum(:commission_cents),
          volume_cents: active.sum(:amount_cents)
        }
      end
    end
  end
end
