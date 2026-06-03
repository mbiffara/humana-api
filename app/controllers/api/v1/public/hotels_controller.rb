module Api
  module V1
    module Public
      # Public list of network hotels. No authentication required.
      class HotelsController < Api::V1::PublicController
        # GET /api/v1/public/hotels?country=ES&q=ibiza&certified=true
        def index
          scope = Hotel.in_country(params[:country])
                       .search(params[:q])
                       .order(:name)
          scope = scope.certified if ActiveModel::Type::Boolean.new.cast(params[:certified])

          render json: {
            hotels: paginate(scope).map { |h| ApiSerializers.hotel(h) },
            meta: meta_for(scope)
          }
        end

        # GET /api/v1/public/hotels/:id
        def show
          hotel = Hotel.find(params[:id])
          render json: { hotel: ApiSerializers.hotel(hotel) }
        end
      end
    end
  end
end
