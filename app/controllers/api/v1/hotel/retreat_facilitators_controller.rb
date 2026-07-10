# Manages facilitators assigned to a retreat. Nested under hotel/retreats.
module Api
  module V1
    module Hotel
      class RetreatFacilitatorsController < BaseController
        before_action :set_retreat

        def index
          facilitators = @retreat.retreat_facilitators.ordered
          render json: { facilitators: facilitators.map { |f| ApiSerializers.retreat_facilitator(f) } }
        end

        def create
          f = @retreat.retreat_facilitators.build(facilitator_params)
          if f.save
            render json: { facilitator: ApiSerializers.retreat_facilitator(f) }, status: :created
          else
            render_unprocessable(f.errors.full_messages)
          end
        end

        def update
          f = @retreat.retreat_facilitators.find(params[:id])
          if f.update(facilitator_params)
            render json: { facilitator: ApiSerializers.retreat_facilitator(f) }
          else
            render_unprocessable(f.errors.full_messages)
          end
        end

        def destroy
          f = @retreat.retreat_facilitators.find(params[:id])
          f.destroy!
          head :no_content
        end

        private

        def set_retreat
          @retreat = current_hotel.retreats.find(params[:retreat_id])
        end

        def facilitator_params
          params.require(:retreat_facilitator).permit(
            :name, :role, :specialty, :avatar_url, :bio, :position
          )
        end
      end
    end
  end
end
