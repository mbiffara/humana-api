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

            # Pre-compute IDs to avoid repeated subqueries
            experience_ids = Experience.where(country_code: country.code).pluck(:id)
            retreat_ids = Retreat.where(country_code: country.code).pluck(:id)
            retreat_day_ids = RetreatDay.where(retreat_id: retreat_ids).pluck(:id)
            # Query hotel IDs via SQL to avoid namespace collision with Api::V1::Hotel module
            hotel_ids = ActiveRecord::Base.connection.select_values(
              ActiveRecord::Base.sanitize_sql_array(
                ["SELECT id FROM hotels WHERE country_code = ?", country.code]
              )
            ).map(&:to_i)
            room_type_ids = RoomType.where(hotel_id: hotel_ids).pluck(:id)

            # Nullify invited_by references before destroying users
            Invitation.where(invited_by_id: user_ids).update_all(invited_by_id: nil)

            # Delete dependents in safe order (skip callbacks for speed)
            Booking.where(experience_id: experience_ids).delete_all
            Booking.where(organization_id: org_ids).delete_all
            Client.where(organization_id: org_ids).delete_all
            Experience.where(id: experience_ids).delete_all

            RetreatImage.where(retreat_id: retreat_ids).delete_all
            RetreatPricing.where(retreat_id: retreat_ids).delete_all
            RetreatInclusion.where(retreat_id: retreat_ids).delete_all
            RetreatFacilitator.where(retreat_id: retreat_ids).delete_all
            RetreatActivity.where(retreat_day_id: retreat_day_ids).delete_all
            RetreatDay.where(id: retreat_day_ids).delete_all
            Retreat.where(id: retreat_ids).delete_all

            # Physical rooms and availability blocks reference room_types with
            # restrictive FKs — clear them (and any lingering booking room
            # refs) before the room types themselves.
            Booking.where(room_type_id: room_type_ids).update_all(room_type_id: nil, room_id: nil)
            AvailabilityBlock.where(room_type_id: room_type_ids).delete_all
            Room.where(room_type_id: room_type_ids).delete_all
            RoomImage.where(room_type_id: room_type_ids).delete_all
            RoomType.where(id: room_type_ids).delete_all
            HotelAmenity.where(hotel_id: hotel_ids).delete_all
            HotelImage.where(hotel_id: hotel_ids).delete_all
            ActiveRecord::Base.connection.execute(
              ActiveRecord::Base.sanitize_sql_array(
                ["DELETE FROM hotels WHERE country_code = ?", country.code]
              )
            )

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
