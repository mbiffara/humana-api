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

          # Total lodging rooms (each booking = 1 room) minus rooms committed
          # to retreats via allocated_rooms in retreat_pricings.
          total_lodging_rooms = inventory.where(experience_id: nil, retreat_id: nil).count
          committed_to_retreats = RetreatPricing
            .joins(:retreat)
            .where(retreats: {
              created_by_organization_id: current_organization.id,
              status: %w[draft pending_review active upcoming]
            })
            .sum("COALESCE(retreat_pricings.allocated_rooms, 0)")

          render json: {
            dashboard: {
              inventory_lodging_spots: [total_lodging_rooms - committed_to_retreats, 0].max,
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
