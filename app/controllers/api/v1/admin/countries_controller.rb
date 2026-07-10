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

          # Require confirmation text (case-insensitive)
          expected = country.name.downcase
          unless params[:confirmation_text].to_s.strip.downcase == expected
            return render json: { error: "Confirmation text does not match" }, status: :unprocessable_entity
          end

          # Cascade: remove all data linked to this country
          ActiveRecord::Base.transaction do
            orgs = Organization.where(country_code: country.code)
            org_ids = orgs.pluck(:id)
            user_ids = User.where(organization_id: org_ids).pluck(:id)

            # Nullify invited_by references before destroying users
            Invitation.where(invited_by_id: user_ids).update_all(invited_by_id: nil)

            # Delete dependents in safe order (skip callbacks for speed)
            Booking.where(organization_id: org_ids).delete_all
            Client.where(organization_id: org_ids).delete_all
            Experience.where(country_code: country.code).delete_all
            RetreatImage.joins(:retreat).where(retreats: { country_code: country.code }).delete_all
            RetreatPricing.joins(:retreat).where(retreats: { country_code: country.code }).delete_all
            RetreatInclusion.joins(:retreat).where(retreats: { country_code: country.code }).delete_all
            RetreatFacilitator.joins(:retreat).where(retreats: { country_code: country.code }).delete_all
            RetreatActivity.joins(retreat_day: :retreat).where(retreats: { country_code: country.code }).delete_all
            RetreatDay.joins(:retreat).where(retreats: { country_code: country.code }).delete_all
            Retreat.where(country_code: country.code).delete_all
            RoomImage.joins(:room_type).where(room_types: { hotel_id: Hotel.where(country_code: country.code).select(:id) }).delete_all
            RoomType.where(hotel_id: Hotel.where(country_code: country.code).select(:id)).delete_all
            HotelAmenity.where(hotel_id: Hotel.where(country_code: country.code).select(:id)).delete_all
            HotelImage.where(hotel_id: Hotel.where(country_code: country.code).select(:id)).delete_all
            Hotel.where(country_code: country.code).delete_all
            Subscription.where(organization_id: org_ids).delete_all
            StripeConnectAccount.where(organization_id: org_ids).delete_all
            Invitation.where(organization_id: org_ids).delete_all
            User.where(organization_id: org_ids).delete_all
            orgs.delete_all
            country.destroy!
          end

          head :no_content
        rescue => e
          render json: { error: e.message }, status: :internal_server_error
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
