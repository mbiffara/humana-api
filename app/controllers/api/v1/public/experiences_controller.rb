module Api
  module V1
    module Public
      # Public feed of published experiences ("packages"). No authentication.
      # Commission data is intentionally omitted from public responses.
      class ExperiencesController < Api::V1::PublicController
        # GET /api/v1/public/experiences?kind=retreat&country=ES&q=ibiza
        def index
          scope = Experience.published
                            .includes(:hotel)
                            .by_kind(params[:kind])
                            .in_country(params[:country])
                            .search(params[:q])
                            .order(:starts_on)

          render json: {
            experiences: paginate(scope).map { |e| ApiSerializers.experience(e, include_commission: false) },
            meta: meta_for(scope)
          }
        end

        # GET /api/v1/public/experiences/:id  (numeric id or slug)
        def show
          exp = Experience.includes(:hotel).find_by(slug: params[:id]) ||
                Experience.includes(:hotel).find(params[:id])

          render json: { experience: ApiSerializers.experience(exp, include_commission: false) }
        end
      end
    end
  end
end
