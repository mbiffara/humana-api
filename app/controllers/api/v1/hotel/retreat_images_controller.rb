# Manages gallery images for a retreat. Nested under hotel/retreats.
module Api
  module V1
    module Hotel
      class RetreatImagesController < BaseController
        before_action :set_retreat

        def index
          images = @retreat.retreat_images.ordered
          render json: { images: images.map { |img| ApiSerializers.retreat_image(img) } }
        end

        def create
          img = @retreat.retreat_images.build(image_params)
          if img.save
            render json: { image: ApiSerializers.retreat_image(img) }, status: :created
          else
            render_unprocessable(img.errors.full_messages)
          end
        end

        def update
          img = @retreat.retreat_images.find(params[:id])
          if img.update(image_params)
            render json: { image: ApiSerializers.retreat_image(img) }
          else
            render_unprocessable(img.errors.full_messages)
          end
        end

        def destroy
          img = @retreat.retreat_images.find(params[:id])
          img.destroy!
          head :no_content
        end

        private

        def set_retreat
          @retreat = current_hotel.retreats.find(params[:retreat_id])
        end

        def image_params
          params.require(:retreat_image).permit(:image_url, :position, :alt_text, :is_cover)
        end
      end
    end
  end
end
