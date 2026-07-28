# Admin view of all retreats across the platform. Supports filtering, search,
# and status management (approve, reject, close).
module Api
  module V1
    module Admin
      class RetreatsController < BaseController
        def index
          scope = Retreat.includes(:hotel, :retreat_images)
          scope = scope.by_type(params[:retreat_type]) if params[:retreat_type].present?
          scope = scope.by_status(params[:status]) if params[:status].present?
          scope = scope.in_country(params[:country_code]) if params[:country_code].present?
          scope = scope.search(params[:q]) if params[:q].present?

          retreats = paginate(scope.order(created_at: :desc))
          render json: {
            retreats: retreats.map { |r| ApiSerializers.retreat(r, include_details: false) },
            meta: meta_for(scope)
          }
        end

        def show
          retreat = Retreat.find(params[:id])
          render json: { retreat: ApiSerializers.retreat(retreat, all_pricing: true) }
        end

        # Approve a pending_review retreat to active status
        def approve
          retreat = Retreat.find(params[:id])
          retreat.publish!
          render json: { retreat: ApiSerializers.retreat(retreat, include_details: false) }
        end

        # Reject a pending_review retreat back to draft
        def reject
          retreat = Retreat.find(params[:id])
          retreat.update!(status: "draft")
          render json: { retreat: ApiSerializers.retreat(retreat, include_details: false) }
        end

        # Close a retreat (remove from marketplace)
        def close
          retreat = Retreat.find(params[:id])
          retreat.update!(status: "closed")
          render json: { retreat: ApiSerializers.retreat(retreat, include_details: false) }
        end
      end
    end
  end
end
