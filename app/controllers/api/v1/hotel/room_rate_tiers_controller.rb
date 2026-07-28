# Volume pricing tiers for a room type (HT-03e). Nested under hotel/room_types.
module Api
  module V1
    module Hotel
      class RoomRateTiersController < BaseController
        before_action :set_room_type

        def index
          tiers = @room_type.room_rate_tiers.ordered
          render json: { rate_tiers: tiers.map { |tier| ApiSerializers.room_rate_tier(tier) } }
        end

        def create
          tier = @room_type.room_rate_tiers.build(tier_params)
          if tier.save
            render json: { rate_tier: ApiSerializers.room_rate_tier(tier) }, status: :created
          else
            render_unprocessable(tier.errors.full_messages)
          end
        end

        def update
          tier = @room_type.room_rate_tiers.find(params[:id])
          if tier.update(tier_params)
            render json: { rate_tier: ApiSerializers.room_rate_tier(tier) }
          else
            render_unprocessable(tier.errors.full_messages)
          end
        end

        def destroy
          tier = @room_type.room_rate_tiers.find(params[:id])
          tier.destroy!
          head :no_content
        end

        private

        def set_room_type
          @room_type = current_hotel.room_types.find(params[:room_type_id])
        end

        def tier_params
          params.require(:rate_tier).permit(
            :min_rooms, :starts_on, :ends_on, :price_per_night_cents, :position
          )
        end
      end
    end
  end
end
