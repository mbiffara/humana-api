module Api
  module V1
    module Hotel
      class ImagesController < BaseController
        # GET /api/v1/hotel/images
        def index
          images = current_hotel.hotel_images.ordered
          render json: { images: images.map { |i| ApiSerializers.hotel_image(i) } }
        end

        # POST /api/v1/hotel/images
        def create
          image = current_hotel.hotel_images.build(image_params)
          image.position = current_hotel.hotel_images.count
          image.save!
          render json: { image: ApiSerializers.hotel_image(image) }, status: :created
        end

        # DELETE /api/v1/hotel/images/:id
        def destroy
          image = current_hotel.hotel_images.find(params[:id])
          image.destroy!
          head :no_content
        end

        # POST /api/v1/hotel/images/batch
        # Replaces the whole gallery in order, keeping each item's category.
        # Exactly one image ends up as the cover: the first one flagged
        # `is_cover`, or the first image when none is flagged. All-or-nothing —
        # an invalid item rolls the replacement back and leaves the gallery
        # untouched.
        def batch
          items = params[:images] || []
          cover_index = items.index { |img| truthy?(img[:is_cover]) } || 0
          images = nil

          ActiveRecord::Base.transaction do
            current_hotel.hotel_images.destroy_all

            images = items.map.with_index do |img, i|
              current_hotel.hotel_images.create!(
                image_url: img[:image_url],
                category: img[:category].presence || "general",
                alt_text: img[:alt_text],
                position: i,
                is_cover: i == cover_index
              )
            end
          end

          render json: { images: images.map { |i| ApiSerializers.hotel_image(i) } }, status: :created
        end

        private

        def image_params
          params.require(:image).permit(:image_url, :category, :is_cover, :alt_text)
        end

        def truthy?(value)
          ActiveModel::Type::Boolean.new.cast(value) == true
        end
      end
    end
  end
end
