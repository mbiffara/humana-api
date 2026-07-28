# Hotel-scoped retreat management. Allows hotel owners to create, edit,
# and manage retreats hosted at their property, including the full program
# (days, activities, facilitators, inclusions, pricing, images).
module Api
  module V1
    module Hotel
      class RetreatsController < BaseController
        def index
          scope = current_hotel.retreats.includes(:hotel, :retreat_images)
          scope = scope.by_status(params[:status]) if params[:status].present?

          retreats = scope.order(created_at: :desc)
          render json: { retreats: retreats.map { |r| ApiSerializers.retreat(r, include_details: false) } }
        end

        def show
          retreat = current_hotel.retreats.find(params[:id])
          render json: { retreat: ApiSerializers.retreat(retreat) }
        end

        def create
          retreat = current_hotel.retreats.build(retreat_params)
          retreat.created_by_organization = current_organization
          retreat.created_by_type = "hotel"

          if retreat.save
            render json: { retreat: ApiSerializers.retreat(retreat) }, status: :created
          else
            render_unprocessable(retreat.errors.full_messages)
          end
        end

        def update
          retreat = current_hotel.retreats.find(params[:id])
          if retreat.update(retreat_params)
            render json: { retreat: ApiSerializers.retreat(retreat) }
          else
            render_unprocessable(retreat.errors.full_messages)
          end
        end

        def destroy
          retreat = current_hotel.retreats.find(params[:id])
          if retreat.status == "draft"
            retreat.destroy!
            head :no_content
          else
            render json: { error: "Only draft retreats can be deleted" }, status: :unprocessable_entity
          end
        end

        # Atomically replace the retreat's full program (days + activities,
        # facilitators, inclusions). All-or-nothing so a mid-request failure
        # can never leave a published retreat with a half-rebuilt program.
        def replace_program
          retreat = current_hotel.retreats.find(params[:id])

          ActiveRecord::Base.transaction do
            retreat.retreat_days.destroy_all
            (params[:days] || []).each_with_index do |day_params, i|
              day = retreat.retreat_days.create!(
                day_number: day_params[:day_number] || i + 1,
                title: day_params[:title],
                description: day_params[:description]
              )
              (day_params[:activities] || []).each_with_index do |activity_params, j|
                day.retreat_activities.create!(
                  name: activity_params[:name],
                  time: activity_params[:time],
                  position: activity_params[:position] || j,
                  duration_minutes: activity_params[:duration_minutes],
                  description: activity_params[:description],
                  category: activity_params[:category],
                  icon: activity_params[:icon]
                )
              end
            end

            retreat.retreat_facilitators.destroy_all
            (params[:facilitators] || []).each_with_index do |facilitator_params, i|
              retreat.retreat_facilitators.create!(
                name: facilitator_params[:name],
                role: facilitator_params[:role] || "assistant",
                specialty: facilitator_params[:specialty],
                avatar_url: facilitator_params[:avatar_url],
                bio: facilitator_params[:bio],
                position: facilitator_params[:position] || i
              )
            end

            retreat.retreat_inclusions.destroy_all
            (params[:inclusions] || []).each_with_index do |inclusion_params, i|
              retreat.retreat_inclusions.create!(
                name: inclusion_params[:name],
                category: inclusion_params[:category],
                icon: inclusion_params[:icon],
                position: inclusion_params[:position] || i
              )
            end
          end

          render json: { retreat: ApiSerializers.retreat(retreat.reload) }
        end

        # Publish a retreat directly, making it visible on the platform
        def publish
          retreat = current_hotel.retreats.find(params[:id])
          if %w[draft pending_review].include?(retreat.status)
            retreat.publish!
            render json: { retreat: ApiSerializers.retreat(retreat) }
          else
            render json: { error: "Only draft retreats can be published" }, status: :unprocessable_entity
          end
        end

        # Submit a draft retreat for admin review
        def submit_for_review
          retreat = current_hotel.retreats.find(params[:id])
          if retreat.status == "draft"
            retreat.update!(status: "pending_review")
            render json: { retreat: ApiSerializers.retreat(retreat, include_details: false) }
          else
            render json: { error: "Only draft retreats can be submitted for review" }, status: :unprocessable_entity
          end
        end

        private

        def retreat_params
          params.require(:retreat).permit(
            :name, :retreat_type, :duration_nights, :starts_on, :ends_on,
            :capacity, :language, :description, :short_description, :location,
            :country, :country_code, :currency, :commission_rate, :cover_image_url
          )
        end
      end
    end
  end
end
