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

        # POST /api/v1/hotel/retreats/:retreat_id/images/batch
        # Replaces the whole gallery in order; first image becomes the cover.
        # All-or-nothing: an invalid image rolls back the entire replacement
        # so a validation failure can never leave a partial gallery or a
        # cover_image_url pointing at a deleted image.
        def batch
          images = nil
          ActiveRecord::Base.transaction do
            @retreat.retreat_images.destroy_all

            images = (params[:images] || []).map.with_index do |img, i|
              @retreat.retreat_images.create!(
                image_url: img[:image_url],
                alt_text: img[:alt_text],
                position: i,
                is_cover: i.zero?
              )
            end
            @retreat.update!(cover_image_url: images.first&.image_url)
          end

          render json: { images: images.map { |img| ApiSerializers.retreat_image(img) } }, status: :created
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
