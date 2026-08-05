module Api
  module V1
    module Office
      class RetreatsController < BaseController
        # GET /api/v1/office/retreats
        def index
          scope = regional_retreats.includes(:hotel)
          scope = scope.where(status: params[:status]) if params[:status].present?
          scope = scope.where(retreat_type: params[:type]) if params[:type].present?
          scope = scope.order(created_at: :desc)

          meta = meta_for(scope)
          paginated = paginate(scope)

          render json: {
            retreats: paginated.map { |r| ApiSerializers.retreat(r, include_details: false) },
            meta: meta
          }
        end

        # GET /api/v1/office/retreats/:id
        def show
          retreat = regional_retreats.find(params[:id])
          render json: { retreat: ApiSerializers.retreat(retreat) }
        end
      end
    end
  end
end
