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

          # Require admin password
          unless current_user.authenticate(params[:password].to_s)
            return render json: { error: "Invalid password" }, status: :forbidden
          end

          # Require confirmation text
          expected = country.name
          unless params[:confirmation_text].to_s.strip == expected
            return render json: { error: "Confirmation text does not match" }, status: :unprocessable_entity
          end

          # Cascade: destroy organizations, hotels, experiences, retreats in this country
          ActiveRecord::Base.transaction do
            Organization.where(country_code: country.code).destroy_all
            Hotel.where(country_code: country.code).destroy_all
            Retreat.where(country_code: country.code).destroy_all
            Experience.where(country_code: country.code).destroy_all
            country.destroy!
          end

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
