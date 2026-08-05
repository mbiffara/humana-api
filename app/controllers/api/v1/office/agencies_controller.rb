module Api
  module V1
    module Office
      class AgenciesController < BaseController
        # GET /api/v1/office/agencies
        def index
          scope = regional_agency_organizations
          scope = scope.search(params[:q]) if params[:q].present?
          scope = scope.order("organizations.name ASC")

          meta = meta_for(scope)
          paginated = paginate(scope)

          render json: {
            agencies: paginated.map { |org| serialize_agency(org) },
            meta: meta
          }
        end

        # GET /api/v1/office/agencies/:id
        def show
          org = regional_agency_organizations.find(params[:id])
          render json: { agency: serialize_agency(org, include_details: true) }
        end

        private

        def serialize_agency(org, include_details: false)
          bookings = org.bookings
          confirmed = bookings.where(status: "confirmed")
          volume = confirmed.sum(:amount_cents)

          data = ApiSerializers.organization(org).merge(
            user_count: org.users.count,
            booking_count: bookings.count,
            confirmed_count: confirmed.count,
            volume_cents: volume,
            office_fee_cents: (volume * office_fee_rate).round
          )

          if include_details
            data[:users] = org.users.map { |u| ApiSerializers.user(u) }
            data[:recent_bookings] = bookings.order(created_at: :desc).limit(5).map { |b| ApiSerializers.booking(b) }
          end

          data
        end
      end
    end
  end
end
