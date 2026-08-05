module Api
  module V1
    module Office
      class BookingsController < BaseController
        # GET /api/v1/office/bookings
        def index
          scope = regional_bookings.includes(:experience, :client, :organization)
          scope = scope.where(status: params[:status]) if params[:status].present?
          scope = scope.where(organization_id: params[:agency_id]) if params[:agency_id].present?
          scope = scope.order(created_at: :desc)

          meta = meta_for(scope)
          paginated = paginate(scope)

          confirmed = regional_bookings.where(status: "confirmed")
          volume = confirmed.sum(:amount_cents)

          render json: {
            bookings: paginated.map { |b| serialize_office_booking(b) },
            summary: {
              total: regional_bookings.count,
              confirmed: confirmed.count,
              volume_cents: volume,
              office_revenue_cents: (volume * office_fee_rate).round
            },
            meta: meta
          }
        end

        # GET /api/v1/office/bookings/:id
        def show
          booking = regional_bookings.includes(:experience, :client, :organization).find(params[:id])
          render json: { booking: serialize_office_booking(booking) }
        end

        private

        def serialize_office_booking(b)
          ApiSerializers.booking(b).merge(
            agency: ApiSerializers.organization(b.organization),
            office_fee_cents: (b.amount_cents * office_fee_rate).round,
            office_fee_rate: office_fee_rate.to_f
          )
        end
      end
    end
  end
end
