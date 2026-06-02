module Api
  module V1
    # Discovery feed of certified experiences. Read-only for network members.
    class ExperiencesController < BaseController
      # GET /api/v1/experiences?kind=retreat&country=ES&q=ibiza
      def index
        scope = Experience.published
                          .includes(:hotel)
                          .by_kind(params[:kind])
                          .in_country(params[:country])
                          .search(params[:q])
                          .order(:starts_on)

        render json: {
          experiences: paginate(scope).map { |e| ApiSerializers.experience(e) },
          meta: meta_for(scope)
        }
      end

      # GET /api/v1/experiences/:id  (id may be a numeric id or a slug)
      def show
        exp = Experience.includes(:hotel).find_by(slug: params[:id]) ||
              Experience.includes(:hotel).find(params[:id])

        render json: { experience: ApiSerializers.experience(exp) }
      end
    end
  end
end
