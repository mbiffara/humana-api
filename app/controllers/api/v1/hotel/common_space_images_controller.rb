# Gallery images for a common space (LOG-143). Nested under
# hotel/common_spaces, mirroring the room type gallery.
module Api
  module V1
    module Hotel
      class CommonSpaceImagesController < BaseController
        MAX_IMAGES = 8

        before_action :set_common_space

        def index
          images = @common_space.common_space_images.ordered
          render json: { images: images.map { |img| ApiSerializers.common_space_image(img) } }
        end

        # POST /api/v1/hotel/common_spaces/:common_space_id/images/batch
        # Replaces the whole gallery in order; the first image becomes the
        # primary and the space's thumbnail. All-or-nothing: an invalid image
        # rolls back the entire replacement.
        def batch
          items = params[:images] || []
          return render_unprocessable("Up to #{MAX_IMAGES} images per space") if items.length > MAX_IMAGES

          images = nil
          ActiveRecord::Base.transaction do
            @common_space.common_space_images.destroy_all

            images = items.map.with_index do |img, i|
              @common_space.common_space_images.create!(
                image_url: img[:image_url],
                alt_text: img[:alt_text],
                position: i,
                is_primary: i.zero?
              )
            end
          end

          render json: { images: images.map { |img| ApiSerializers.common_space_image(img) } },
                 status: :created
        end

        private

        def set_common_space
          @common_space = current_hotel.common_spaces.find(params[:common_space_id])
        end
      end
    end
  end
end
