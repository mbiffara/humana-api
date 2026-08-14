# Agency-scoped retreat management. Allows agencies to create retreats
# at partner hotels, manage their programs, and submit for admin review.
# Scoped to retreats where `created_by_organization == current_organization`.
module Api
  module V1
    module Agency
      class RetreatsController < BaseController
        before_action :set_retreat, only: %i[show update destroy submit_for_review replace_program replace_pricings]

        def index
          scope = Retreat.where(created_by_organization: current_organization)
                         .includes(:hotel, :retreat_images)
          scope = scope.by_status(params[:status]) if params[:status].present?

          retreats = scope.order(created_at: :desc)
          render json: { retreats: retreats.map { |r| ApiSerializers.retreat(r, include_details: false) } }
        end

        def show
          render json: { retreat: ApiSerializers.retreat(@retreat, all_pricing: true) }
        end

        def create
          hotel = ::Hotel.find(params[:retreat][:hotel_id])
          retreat = hotel.retreats.build(retreat_params)
          retreat.created_by_organization = current_organization
          retreat.created_by_type = "agency"

          if retreat.save
            render json: { retreat: ApiSerializers.retreat(retreat, all_pricing: true) }, status: :created
          else
            render_unprocessable(retreat.errors.full_messages)
          end
        end

        def update
          if @retreat.update(retreat_params)
            render json: { retreat: ApiSerializers.retreat(@retreat, all_pricing: true) }
          else
            render_unprocessable(@retreat.errors.full_messages)
          end
        end

        def destroy
          if @retreat.status == "draft"
            @retreat.destroy!
            head :no_content
          else
            render json: { error: "Only draft retreats can be deleted" }, status: :unprocessable_entity
          end
        end

        def submit_for_review
          if @retreat.status == "draft"
            @retreat.update!(status: "active", published_at: Time.current)
            render json: { retreat: ApiSerializers.retreat(@retreat, include_details: false) }
          else
            render json: { error: "Only draft retreats can be published" }, status: :unprocessable_entity
          end
        end

        def replace_pricings
          ActiveRecord::Base.transaction do
            @retreat.retreat_pricings.destroy_all
            (params[:pricings] || []).each do |pricing_params|
              @retreat.retreat_pricings.create!(
                room_type_id: pricing_params[:room_type_id],
                price_per_guest_cents: pricing_params[:price_per_guest_cents],
                allocated_rooms: pricing_params[:allocated_rooms]
              )
            end
          end

          render json: { retreat: ApiSerializers.retreat(@retreat.reload, all_pricing: true) }
        end

        def replace_program
          ActiveRecord::Base.transaction do
            @retreat.retreat_days.destroy_all
            (params[:days] || []).each_with_index do |day_params, i|
              day = @retreat.retreat_days.create!(
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

            @retreat.retreat_facilitators.destroy_all
            (params[:facilitators] || []).each_with_index do |facilitator_params, i|
              @retreat.retreat_facilitators.create!(
                name: facilitator_params[:name],
                role: facilitator_params[:role] || "assistant",
                specialty: facilitator_params[:specialty],
                avatar_url: facilitator_params[:avatar_url],
                bio: facilitator_params[:bio],
                position: facilitator_params[:position] || i
              )
            end

            @retreat.retreat_inclusions.destroy_all
            (params[:inclusions] || []).each_with_index do |inclusion_params, i|
              @retreat.retreat_inclusions.create!(
                name: inclusion_params[:name],
                category: inclusion_params[:category],
                icon: inclusion_params[:icon],
                position: inclusion_params[:position] || i
              )
            end

            @retreat.retreat_pricings.destroy_all
            (params[:pricings] || []).each do |pricing_params|
              @retreat.retreat_pricings.create!(
                room_type_id: pricing_params[:room_type_id],
                price_per_guest_cents: pricing_params[:price_per_guest_cents],
                allocated_rooms: pricing_params[:allocated_rooms]
              )
            end
          end

          render json: { retreat: ApiSerializers.retreat(@retreat.reload) }
        end

        private

        def set_retreat
          @retreat = Retreat.where(created_by_organization: current_organization).find(params[:id])
        end

        def retreat_params
          params.require(:retreat).permit(
            :name, :retreat_type, :duration_nights, :starts_on, :ends_on,
            :capacity, :language, :description, :short_description, :location,
            :country, :country_code, :currency, :commission_rate, :cover_image_url,
            :hotel_id
          )
        end
      end
    end
  end
end
