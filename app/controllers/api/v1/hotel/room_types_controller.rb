# Hotel-scoped CRUD for room types. Allows hotel owners to define their
# room categories, capacities, and nightly rates.
module Api
  module V1
    module Hotel
      class RoomTypesController < BaseController
        def index
          room_types = current_hotel.room_types.ordered
          render json: { room_types: room_types.map { |rt| ApiSerializers.room_type(rt) } }
        end

        def show
          rt = current_hotel.room_types.find(params[:id])
          render json: { room_type: ApiSerializers.room_type(rt) }
        end

        def create
          rt = current_hotel.room_types.build(room_type_params)
          if rt.save
            render json: { room_type: ApiSerializers.room_type(rt) }, status: :created
          else
            render_unprocessable(rt.errors.full_messages)
          end
        end

        def update
          rt = current_hotel.room_types.find(params[:id])
          if rt.update(room_type_params)
            render json: { room_type: ApiSerializers.room_type(rt) }
          else
            render_unprocessable(rt.errors.full_messages)
          end
        end

        def destroy
          rt = current_hotel.room_types.find(params[:id])
          rt.destroy!
          head :no_content
        end

        private

        def room_type_params
          params.require(:room_type).permit(
            :name, :category, :capacity, :area_sqm, :price_per_night_cents,
            :currency, :description, :image_url, :total_rooms, :position,
            :bed_type
          )
        end
      end
    end
  end
end
