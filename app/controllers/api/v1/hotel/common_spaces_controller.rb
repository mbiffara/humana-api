# Hotel-scoped CRUD for common spaces (LOG-143). Lets hotel owners describe
# the halls, yoga rooms, terraces and gardens they can offer to a group.
module Api
  module V1
    module Hotel
      class CommonSpacesController < BaseController
        def index
          spaces = current_hotel.common_spaces.ordered.includes(:common_space_images)
          render json: { common_spaces: spaces.map { |cs| ApiSerializers.common_space(cs) } }
        end

        def show
          space = find_space
          render json: { common_space: ApiSerializers.common_space(space) }
        end

        def create
          space = current_hotel.common_spaces.build(common_space_params)
          space.position = next_position if params[:common_space][:position].blank?

          if space.save
            render json: { common_space: ApiSerializers.common_space(space) }, status: :created
          else
            render_unprocessable(space.errors.full_messages)
          end
        end

        def update
          space = find_space
          if space.update(common_space_params)
            render json: { common_space: ApiSerializers.common_space(space) }
          else
            render_unprocessable(space.errors.full_messages)
          end
        end

        def destroy
          find_space.destroy!
          head :no_content
        end

        private

        def find_space
          current_hotel.common_spaces.find(params[:id])
        end

        # Appended at the end of the hotel's list unless the caller orders it.
        def next_position
          (current_hotel.common_spaces.maximum(:position) || -1) + 1
        end

        def common_space_params
          params.require(:common_space).permit(
            :name, :space_type, :space_type_other,
            :capacity_seated, :capacity_yoga, :capacity_auditorium,
            :capacity_banquet, :capacity_workshop,
            :area_sqm, :floor_type, :floor_type_other,
            :exclusive_for_groups, :equipment_other, :position,
            equipment: []
          )
        end
      end
    end
  end
end
