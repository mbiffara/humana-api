# Admin bookings — view all bookings across the platform with filters.
# Supports filtering by country, organization (agency/hotel), status, and date range.
module Api
  module V1
    module Admin
      class BookingsController < BaseController
        def index
          scope = Booking.includes(:organization, :client, :experience, :hotel, :room_type)

          # Status filter
          scope = scope.where(status: params[:status]) if params[:status].present?

          # Country filter — match via experience or direct hotel
          if params[:country_code].present?
            scope = scope.where(
              "EXISTS (SELECT 1 FROM experiences WHERE experiences.id = bookings.experience_id AND experiences.country_code = :cc)" \
              " OR EXISTS (SELECT 1 FROM hotels WHERE hotels.id = bookings.hotel_id AND hotels.country_code = :cc)",
              cc: params[:country_code]
            )
          end

          # Agency (organization) filter
          scope = scope.where(organization_id: params[:organization_id]) if params[:organization_id].present?

          # Hotel filter
          if params[:hotel_id].present?
            scope = scope.where(
              "bookings.hotel_id = :hid" \
              " OR EXISTS (SELECT 1 FROM experiences WHERE experiences.id = bookings.experience_id AND experiences.hotel_id = :hid)",
              hid: params[:hotel_id]
            )
          end

          # Date range
          if params[:from].present?
            from_date = Date.parse(params[:from])
            scope = scope.where("bookings.created_at >= ?", from_date.beginning_of_day)
          end
          if params[:to].present?
            to_date = Date.parse(params[:to])
            scope = scope.where("bookings.created_at <= ?", to_date.end_of_day)
          end

          # Search by reference
          scope = scope.where("bookings.reference ILIKE ?", "%#{params[:q]}%") if params[:q].present?

          total_scope = scope
          bookings = paginate(scope.order(created_at: :desc))

          render json: {
            bookings: bookings.map { |b| serialize_admin_booking(b) },
            meta: meta_for(total_scope),
            summary: {
              total_amount_cents: total_scope.sum(:amount_cents),
              total_commission_cents: total_scope.sum(:commission_cents),
              count: total_scope.count,
            },
          }
        rescue Date::Error
          render_bad_request("Invalid date format. Use YYYY-MM-DD.")
        end

        private

        def serialize_admin_booking(b)
          hotel = b.hotel || b.experience&.hotel
          {
            id: b.id,
            reference: b.reference,
            status: b.status,
            guests: b.guests,
            starts_on: b.starts_on,
            ends_on: b.ends_on,
            amount_cents: b.amount_cents,
            amount: b.amount,
            currency: b.currency,
            commission_cents: b.commission_cents,
            commission: b.commission,
            notes: b.notes,
            created_at: b.created_at,
            client: b.client ? { id: b.client.id, name: b.client.name, email: b.client.email } : nil,
            agency: ApiSerializers.organization(b.organization),
            hotel: hotel ? {
              id: hotel.id,
              name: hotel.name,
              city: hotel.city,
              country: hotel.country,
              country_code: hotel.country_code,
            } : nil,
            experience: b.experience ? {
              id: b.experience.id,
              title: b.experience.title,
              kind: b.experience.kind,
            } : nil,
            room_type: b.room_type ? { id: b.room_type.id, name: b.room_type.name } : nil,
          }
        end
      end
    end
  end
end
