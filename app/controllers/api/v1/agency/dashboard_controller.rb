# Agency workspace dashboard. Aggregates booking KPIs and active client count
# for the agency landing screen.
module Api
  module V1
    module Agency
      class DashboardController < BaseController
        def show
          bookings = current_organization.bookings
          active   = bookings.active
          inventory = active.where(client_id: nil)

          # Count bookings on retreats created by this agency
          retreat_ids = Retreat.where(created_by_organization: current_organization).select(:id)
          retreat_sales_count = Booking.active.where(retreat_id: retreat_ids).count

          render json: {
            dashboard: {
              inventory_lodging_spots: inventory.where(experience_id: nil, retreat_id: nil).sum(:guests),
              inventory_retreat_count: inventory.where.not(retreat_id: nil).or(inventory.where.not(experience_id: nil)).count,
              commission_earned_cents: active.sum(:commission_cents),
              volume_cents: active.sum(:amount_cents),
              active_clients: current_organization.clients.count,
              member_since: current_organization.created_at.to_date,
              retreat_sales_count: retreat_sales_count
            }
          }
        end
      end
    end
  end
end
