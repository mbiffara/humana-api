module Api
  module V1
    module Office
      class DashboardController < BaseController
        # GET /api/v1/office/dashboard
        def show
          hotel_orgs = regional_hotel_organizations
          agency_orgs = regional_agency_organizations
          bookings = regional_bookings
          confirmed = bookings.where(status: "confirmed")
          retreats = regional_retreats

          volume_cents = confirmed.sum(:amount_cents)
          revenue_cents = (volume_cents * office_fee_rate).round

          # This month stats
          this_month_start = Date.current.beginning_of_month
          bookings_this_month = bookings.where("bookings.created_at >= ?", this_month_start).count

          # Countries represented
          hotel_countries = regional_hotels.distinct.pluck(:country_code).compact.uniq.length

          # Top hotels by booking revenue
          top_hotels = ::Hotel
            .joins(experiences: :bookings)
            .where(id: regional_hotels.select(:id))
            .where(bookings: { status: "confirmed" })
            .select(
              "hotels.*, " \
              "SUM(bookings.amount_cents) AS total_revenue_cents, " \
              "COUNT(bookings.id) AS booking_count"
            )
            .group("hotels.id")
            .order("total_revenue_cents DESC")
            .limit(4)

          # Top agencies by booking volume
          top_agency_data = Booking
            .where(organization_id: agency_orgs.select(:id))
            .where(status: "confirmed")
            .group(:organization_id)
            .select(
              "organization_id, " \
              "SUM(amount_cents) AS total_volume_cents, " \
              "COUNT(*) AS booking_count"
            )
            .order("total_volume_cents DESC")
            .limit(4)

          top_agency_ids = top_agency_data.map(&:organization_id)
          top_agency_orgs = Organization.where(id: top_agency_ids).index_by(&:id)
          top_agencies = top_agency_data.map do |row|
            org = top_agency_orgs[row.organization_id]
            next unless org
            {
              id: org.id,
              name: org.name,
              city: org.city,
              country: org.country,
              total_volume_cents: row.total_volume_cents.to_i,
              booking_count: row.booking_count.to_i
            }
          end.compact

          # Pending organizations awaiting admin approval
          pending_orgs = regional_organizations
            .where(status: "pending")
            .order(created_at: :desc)
            .limit(6)

          render json: {
            dashboard: {
              hotels_count: hotel_orgs.count,
              agencies_count: agency_orgs.count,
              total_bookings: bookings.count,
              confirmed_bookings: confirmed.count,
              bookings_this_month: bookings_this_month,
              published_retreats: retreats.where(status: "active").count,
              pending_retreats: retreats.where(status: "pending_review").count,
              volume_cents: volume_cents,
              office_revenue_cents: revenue_cents,
              office_fee_rate: office_fee_rate.to_f,
              country: current_organization.country,
              country_code: current_organization.country_code,
              countries_count: hotel_countries,
              member_since: current_organization.created_at.to_date,
              top_hotels: top_hotels.map { |h|
                serialized = ApiSerializers.hotel(h)
                serialized.merge(
                  total_revenue_cents: h.total_revenue_cents.to_i,
                  booking_count: h.booking_count.to_i
                )
              },
              top_agencies: top_agencies,
              pending_organizations: pending_orgs.map { |o| ApiSerializers.organization(o) }
            }
          }
        end

        # POST /api/v1/office/dashboard/contact_admin
        def contact_admin
          subject = params[:subject].to_s.strip
          message = params[:message].to_s.strip

          if message.blank?
            return render_bad_request("Message is required")
          end

          begin
            OfficeMailer.contact_admin(
              office: current_organization,
              sender: current_user,
              subject: subject.presence || "Office request",
              message: message
            ).deliver_now
          rescue StandardError => e
            Rails.logger.warn("[OfficeMailer] Email delivery failed: #{e.message}")
            return render json: { error: "Email delivery failed. Please try again later." }, status: :service_unavailable
          end

          render json: { success: true, message: "Email sent to info@humana.global" }
        end
      end
    end
  end
end
