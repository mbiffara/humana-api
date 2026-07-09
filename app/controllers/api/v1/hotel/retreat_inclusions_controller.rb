# Manages inclusions for a retreat. Nested under hotel/retreats.
module Api
  module V1
    module Hotel
      class RetreatInclusionsController < BaseController
        before_action :set_retreat

        def index
          inclusions = @retreat.retreat_inclusions.ordered
          render json: { inclusions: inclusions.map { |i| ApiSerializers.retreat_inclusion(i) } }
        end

        def create
          inc = @retreat.retreat_inclusions.build(inclusion_params)
          if inc.save
            render json: { inclusion: ApiSerializers.retreat_inclusion(inc) }, status: :created
          else
            render_unprocessable(inc.errors.full_messages)
          end
        end

        def update
          inc = @retreat.retreat_inclusions.find(params[:id])
          if inc.update(inclusion_params)
            render json: { inclusion: ApiSerializers.retreat_inclusion(inc) }
          else
            render_unprocessable(inc.errors.full_messages)
          end
        end

        def destroy
          inc = @retreat.retreat_inclusions.find(params[:id])
          inc.destroy!
          head :no_content
        end

        private

        def set_retreat
          @retreat = current_hotel.retreats.find(params[:retreat_id])
        end

        def inclusion_params
          params.require(:retreat_inclusion).permit(:name, :category, :icon, :position)
        end
      end
    end
  end
end
