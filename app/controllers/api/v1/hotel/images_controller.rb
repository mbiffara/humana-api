module Api
  module V1
    module Hotel
      class ImagesController < BaseController
        # GET /api/v1/hotel/images
        def index
          images = current_hotel.hotel_images.order(:position)
          render json: { images: images.map { |i| serialize_image(i) } }
        end

        # POST /api/v1/hotel/images
        def create
          image = current_hotel.hotel_images.build(image_params)
          image.position = current_hotel.hotel_images.count
          image.save!
          render json: { image: serialize_image(image) }, status: :created
        end

        # DELETE /api/v1/hotel/images/:id
        def destroy
          image = current_hotel.hotel_images.find(params[:id])
          image.destroy!
          head :no_content
        end

        # POST /api/v1/hotel/images/batch
        def batch
          current_hotel.hotel_images.destroy_all

          images = (params[:images] || []).map.with_index do |img, i|
            current_hotel.hotel_images.create!(
              image_url: img[:image_url],
              category: img[:category] || "property",
              position: i,
              is_cover: i == 0
            )
          end

          render json: { images: images.map { |i| serialize_image(i) } }, status: :created
        end

        private

        def image_params
          params.require(:image).permit(:image_url, :category, :is_cover)
        end

        def serialize_image(i)
          { id: i.id, image_url: i.image_url, category: i.category, position: i.position, is_cover: i.is_cover }
        end
      end
    end
  end
end
