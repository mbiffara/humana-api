module Api
  module V1
    module Office
      class HotelsController < BaseController
        # GET /api/v1/office/hotels
        def index
          scope = regional_hotels.includes(:organization)
          scope = scope.where("hotels.name ILIKE :q OR hotels.city ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?
          scope = scope.order("hotels.name ASC")

          meta = meta_for(scope)
          paginated = paginate(scope)

          render json: {
            hotels: paginated.map { |h| ApiSerializers.hotel(h) },
            meta: meta
          }
        end

        # GET /api/v1/office/hotels/:id
        def show
          hotel = regional_hotels.find(params[:id])
          render json: { hotel: ApiSerializers.hotel_full(hotel) }
        end
      end
    end
  end
end
