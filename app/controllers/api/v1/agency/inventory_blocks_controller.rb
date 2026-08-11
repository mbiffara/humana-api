# Agency-scoped inventory block management. Tracks room allotments
# at partner hotels, with computed availability.
module Api
  module V1
    module Agency
      class InventoryBlocksController < BaseController
        def index
          scope = InventoryBlock.where(organization: current_organization).active
          scope = scope.for_hotel(params[:hotel_id]) if params[:hotel_id].present?
          if params[:from].present? && params[:to].present?
            scope = scope.covering_dates(params[:from], params[:to])
          end

          blocks = scope.includes(:room_type, :hotel).order(:starts_on)
          render json: {
            inventory_blocks: blocks.map { |b| ApiSerializers.inventory_block(b) }
          }
        end

        def create
          block = InventoryBlock.new(block_params)
          block.organization = current_organization

          if block.save
            render json: { inventory_block: ApiSerializers.inventory_block(block) }, status: :created
          else
            render_unprocessable(block.errors.full_messages)
          end
        end

        def update
          block = InventoryBlock.where(organization: current_organization).find(params[:id])
          if block.update(block_params)
            render json: { inventory_block: ApiSerializers.inventory_block(block) }
          else
            render_unprocessable(block.errors.full_messages)
          end
        end

        def destroy
          block = InventoryBlock.where(organization: current_organization).find(params[:id])
          block.destroy!
          head :no_content
        end

        private

        def block_params
          params.require(:inventory_block).permit(
            :hotel_id, :room_type_id, :total_rooms,
            :starts_on, :ends_on, :cost_per_night_cents, :currency, :status
          )
        end
      end
    end
  end
end
