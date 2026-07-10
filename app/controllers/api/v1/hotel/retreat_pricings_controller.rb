# Manages per-room-type pricing for a retreat. Nested under hotel/retreats.
module Api
  module V1
    module Hotel
      class RetreatPricingsController < BaseController
        before_action :set_retreat

        def index
          pricings = @retreat.retreat_pricings.includes(:room_type)
          render json: { pricings: pricings.map { |p| ApiSerializers.retreat_pricing(p) } }
        end

        def create
          pricing = @retreat.retreat_pricings.build(pricing_params)
          if pricing.save
            render json: { pricing: ApiSerializers.retreat_pricing(pricing) }, status: :created
          else
            render_unprocessable(pricing.errors.full_messages)
          end
        end

        def update
          pricing = @retreat.retreat_pricings.find(params[:id])
          if pricing.update(pricing_params)
            render json: { pricing: ApiSerializers.retreat_pricing(pricing) }
          else
            render_unprocessable(pricing.errors.full_messages)
          end
        end

        def destroy
          pricing = @retreat.retreat_pricings.find(params[:id])
          pricing.destroy!
          head :no_content
        end

        private

        def set_retreat
          @retreat = current_hotel.retreats.find(params[:retreat_id])
        end

        def pricing_params
          params.require(:retreat_pricing).permit(
            :room_type_id, :price_per_guest_cents, :currency, :occupancy_label, :max_guests
          )
        end
      end
    end
  end
end
