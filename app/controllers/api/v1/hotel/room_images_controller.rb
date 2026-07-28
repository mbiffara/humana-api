# Gallery images for a room type (HT-03c). Nested under hotel/room_types.
module Api
  module V1
    module Hotel
      class RoomImagesController < BaseController
        before_action :set_room_type

        def index
          images = @room_type.room_images.ordered
          render json: { images: images.map { |img| ApiSerializers.room_image(img) } }
        end

        # POST /api/v1/hotel/room_types/:room_type_id/images/batch
        # Replaces the whole gallery in order; the first image becomes the
        # primary and the room type's thumbnail. All-or-nothing: an invalid
        # image rolls back the entire replacement.
        def batch
          images = nil
          ActiveRecord::Base.transaction do
            @room_type.room_images.destroy_all

            images = (params[:images] || []).map.with_index do |img, i|
              @room_type.room_images.create!(
                image_url: img[:image_url],
                alt_text: img[:alt_text],
                position: i,
                is_primary: i.zero?
              )
            end
            @room_type.update!(image_url: images.first&.image_url)
          end

          render json: { images: images.map { |img| ApiSerializers.room_image(img) } }, status: :created
        end

        private

        def set_room_type
          @room_type = current_hotel.room_types.find(params[:room_type_id])
        end
      end
    end
  end
end
