# Manages activities within a retreat day. Nested under hotel/retreats/days.
module Api
  module V1
    module Hotel
      class RetreatActivitiesController < BaseController
        before_action :set_day

        def index
          activities = @day.retreat_activities.ordered
          render json: { activities: activities.map { |a| ApiSerializers.retreat_activity(a) } }
        end

        def create
          activity = @day.retreat_activities.build(activity_params)
          if activity.save
            render json: { activity: ApiSerializers.retreat_activity(activity) }, status: :created
          else
            render_unprocessable(activity.errors.full_messages)
          end
        end

        def update
          activity = @day.retreat_activities.find(params[:id])
          if activity.update(activity_params)
            render json: { activity: ApiSerializers.retreat_activity(activity) }
          else
            render_unprocessable(activity.errors.full_messages)
          end
        end

        def destroy
          activity = @day.retreat_activities.find(params[:id])
          activity.destroy!
          head :no_content
        end

        private

        def set_day
          retreat = current_hotel.retreats.find(params[:retreat_id])
          @day = retreat.retreat_days.find(params[:day_id])
        end

        def activity_params
          params.require(:retreat_activity).permit(
            :name, :time, :duration_minutes, :position, :description, :category, :icon
          )
        end
      end
    end
  end
end
