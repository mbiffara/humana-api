# Hotel-scoped CRUD for physical rooms. Rooms are auto-generated from each
# room type's total_rooms count; hotels can rename, renumber, add or remove
# them, and flag rooms under maintenance. total_rooms is kept in sync.
module Api
  module V1
    module Hotel
      class RoomsController < BaseController
        # GET /api/v1/hotel/rooms?room_type_id=1&status=available
        def index
          rooms = current_hotel.rooms
                               .by_room_type(params[:room_type_id])
                               .by_status(params[:status])
                               .ordered
          render json: { rooms: rooms.map { |r| ApiSerializers.room(r) } }
        end

        # POST /api/v1/hotel/rooms
        def create
          room = current_hotel.rooms.build(room_params)
          room.auto_generated = false
          if room.save
            refresh_total(room.room_type)
            render json: { room: ApiSerializers.room(room) }, status: :created
          else
            render_unprocessable(room.errors.full_messages)
          end
        end

        # PATCH/PUT /api/v1/hotel/rooms/:id
        def update
          room = current_hotel.rooms.find(params[:id])
          previous_type = room.room_type
          if room.update(room_params)
            refresh_total(room.room_type)
            refresh_total(previous_type) if previous_type != room.room_type
            render json: { room: ApiSerializers.room(room) }
          else
            render_unprocessable(room.errors.full_messages)
          end
        end

        # DELETE /api/v1/hotel/rooms/:id
        def destroy
          room = current_hotel.rooms.find(params[:id])
          room.destroy!
          refresh_total(room.room_type)
          head :no_content
        end

        private

        def room_params
          params.require(:room).permit(:room_type_id, :number, :status, :notes)
        end

        # update_column skips callbacks, so this cannot re-trigger room syncing.
        def refresh_total(room_type)
          room_type.update_column(:total_rooms, room_type.rooms.count)
        end
      end
    end
  end
end
