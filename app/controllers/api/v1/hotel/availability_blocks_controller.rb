# Hotel-scoped CRUD for availability blocks — date-ranged inventory closures
# (seasonal shutdowns, renovations, limited allotment). All dates are open by
# default; blocks only subtract from availability.
module Api
  module V1
    module Hotel
      class AvailabilityBlocksController < BaseController
        # GET /api/v1/hotel/availability_blocks?room_type_id=1
        def index
          blocks = current_hotel.availability_blocks
                                .by_room_type(params[:room_type_id])
                                .ordered
          render json: { availability_blocks: blocks.map { |b| ApiSerializers.availability_block(b) } }
        end

        # POST /api/v1/hotel/availability_blocks
        def create
          block = current_hotel.availability_blocks.build(block_params)
          if block.save
            render json: { availability_block: ApiSerializers.availability_block(block) }, status: :created
          else
            render_unprocessable(block.errors.full_messages)
          end
        end

        # DELETE /api/v1/hotel/availability_blocks/:id
        def destroy
          current_hotel.availability_blocks.find(params[:id]).destroy!
          head :no_content
        end

        private

        def block_params
          params.require(:availability_block).permit(:room_type_id, :starts_on, :ends_on, :units, :reason)
        end
      end
    end
  end
end
