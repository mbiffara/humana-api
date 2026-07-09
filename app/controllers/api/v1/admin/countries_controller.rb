# Admin CRUD for enabled countries. Controls which countries are available
# for organization assignment and marketplace filtering.
module Api
  module V1
    module Admin
      class CountriesController < BaseController
        def index
          scope = Country.all
          scope = scope.by_region(params[:region]) if params[:region].present?
          scope = scope.search(params[:q]) if params[:q].present?
          scope = scope.enabled if params[:enabled] == "true"

          countries = scope.order(:name)
          render json: { countries: countries.map { |c| ApiSerializers.country(c) } }
        end

        def show
          country = Country.find(params[:id])
          render json: { country: ApiSerializers.country(country) }
        end

        def create
          country = Country.new(country_params)
          if country.save
            render json: { country: ApiSerializers.country(country) }, status: :created
          else
            render_unprocessable(country.errors.full_messages)
          end
        end

        def update
          country = Country.find(params[:id])
          if country.update(country_params)
            render json: { country: ApiSerializers.country(country) }
          else
            render_unprocessable(country.errors.full_messages)
          end
        end

        def destroy
          country = Country.find(params[:id])
          country.destroy!
          head :no_content
        end

        private

        def country_params
          params.require(:country).permit(:name, :code, :flag_emoji, :status,
                                          :enabled, :region, :currency_code, :timezone)
        end
      end
    end
  end
end
