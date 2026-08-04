module Api
  module V1
    module Public
      class RetreatsController < PublicController
        def index
          scope = Retreat.published.includes(:hotel, :retreat_images)
          scope = scope.by_type(params[:type]) if params[:type].present?
          scope = scope.in_country(params[:country_code]) if params[:country_code].present?
          scope = scope.search(params[:q]) if params[:q].present?
          scope = scope.order(starts_on: :asc)

          retreats = paginate(scope)
          render json: {
            retreats: retreats.map { |r| ApiSerializers.retreat(r, include_details: false, include_commission: false) },
            meta: meta_for(scope)
          }
        end

        def show
          retreat = Retreat.published
            .includes(
              :hotel, :retreat_facilitators, :retreat_inclusions, :retreat_images,
              retreat_days: :retreat_activities,
              retreat_pricings: :room_type
            )
            .find_by(slug: params[:id]) || Retreat.published.find(params[:id])

          render json: {
            retreat: ApiSerializers.retreat(retreat, include_details: true, include_commission: false)
          }
        end
      end
    end
  end
end
