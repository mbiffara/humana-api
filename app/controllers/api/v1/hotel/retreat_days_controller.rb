# Manages days within a retreat's program. Nested under hotel/retreats.
module Api
  module V1
    module Hotel
      class RetreatDaysController < BaseController
        before_action :set_retreat

        def index
          days = @retreat.retreat_days.ordered.includes(retreat_activities: [])
          render json: { days: days.map { |d| ApiSerializers.retreat_day(d) } }
        end

        def create
          day = @retreat.retreat_days.build(day_params)
          if day.save
            render json: { day: ApiSerializers.retreat_day(day) }, status: :created
          else
            render_unprocessable(day.errors.full_messages)
          end
        end

        def update
          day = @retreat.retreat_days.find(params[:id])
          if day.update(day_params)
            render json: { day: ApiSerializers.retreat_day(day) }
          else
            render_unprocessable(day.errors.full_messages)
          end
        end

        def destroy
          day = @retreat.retreat_days.find(params[:id])
          day.destroy!
          head :no_content
        end

        private

        def set_retreat
          @retreat = current_hotel.retreats.find(params[:retreat_id])
        end

        def day_params
          params.require(:retreat_day).permit(:day_number, :title, :description)
        end
      end
    end
  end
end
