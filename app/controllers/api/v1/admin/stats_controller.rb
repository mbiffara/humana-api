# Returns aggregated KPI stats for the admin dashboard.
# Accepts optional date range filters: ?from=YYYY-MM-DD&to=YYYY-MM-DD
module Api
  module V1
    module Admin
      class StatsController < BaseController
        def index
          from_date = params[:from].present? ? Date.parse(params[:from]) : nil
          to_date   = params[:to].present?   ? Date.parse(params[:to])   : nil

          # Only count organizations that have at least one user
          orgs = Organization.where.not(kind: "admin")
                              .where("EXISTS (SELECT 1 FROM users WHERE users.organization_id = organizations.id)")
          bookings = Booking.all

          if from_date
            orgs = orgs.where("organizations.created_at >= ?", from_date.beginning_of_day)
            bookings = bookings.where("bookings.created_at >= ?", from_date.beginning_of_day)
          end
          if to_date
            orgs = orgs.where("organizations.created_at <= ?", to_date.end_of_day)
            bookings = bookings.where("bookings.created_at <= ?", to_date.end_of_day)
          end

          agencies = orgs.where(kind: "agency").count
          hotels   = orgs.where(kind: "hotel").count
          booking_count = bookings.count
          gmv_cents = bookings.sum(:amount_cents)

          # Pending counts per kind (not filtered by date range, only orgs with users)
          has_users = "EXISTS (SELECT 1 FROM users WHERE users.organization_id = organizations.id)"
          pending_agencies = Organization.where(kind: "agency", status: "pending").where(has_users).count
          pending_hotels   = Organization.where(kind: "hotel", status: "pending").where(has_users).count

          platform_since = Organization.minimum(:created_at)&.to_date || Date.today

          render json: {
            stats: {
              agencies: agencies,
              hotels: hotels,
              bookings: booking_count,
              gmv_cents: gmv_cents,
              pending_agencies: pending_agencies,
              pending_hotels: pending_hotels,
              platform_since: platform_since.iso8601,
            },
          }
        rescue Date::Error
          render_bad_request("Invalid date format. Use YYYY-MM-DD.")
        end
      end
    end
  end
end
