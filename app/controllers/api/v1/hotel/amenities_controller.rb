module Api
  module V1
    module Hotel
      class AmenitiesController < BaseController
        # GET /api/v1/hotel/amenities
        def index
          amenities = current_hotel.hotel_amenities.order(:category, :position)
          render json: { amenities: amenities.map { |a| serialize_amenity(a) } }
        end

        # POST /api/v1/hotel/amenities/batch
        def batch
          # Replace all amenities with the submitted list
          current_hotel.hotel_amenities.destroy_all

          amenities = (params[:amenities] || []).map.with_index do |a, i|
            current_hotel.hotel_amenities.create!(
              name: a[:name],
              category: a[:category] || "general",
              icon: a[:icon],
              position: i
            )
          end

          render json: { amenities: amenities.map { |a| serialize_amenity(a) } }, status: :created
        end

        private

        def serialize_amenity(a)
          { id: a.id, name: a.name, category: a.category, icon: a.icon, position: a.position }
        end
      end
    end
  end
end
