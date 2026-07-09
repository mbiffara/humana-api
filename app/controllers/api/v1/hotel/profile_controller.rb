module Api
  module V1
    module Hotel
      class ProfileController < BaseController
        # GET /api/v1/hotel/profile
        def show
          render json: {
            hotel: current_hotel ? ApiSerializers.hotel_full(current_hotel) : nil,
            organization: ApiSerializers.organization(current_organization, include_onboarding: true)
          }
        end

        # PATCH /api/v1/hotel/profile
        def update
          hotel = current_hotel || current_organization.hotels.build
          hotel.assign_attributes(hotel_params)
          hotel.save!
          render json: {
            hotel: ApiSerializers.hotel_full(hotel),
            organization: ApiSerializers.organization(current_organization, include_onboarding: true)
          }
        end

        # POST /api/v1/hotel/profile/submit_for_review
        def submit_for_review
          current_organization.update!(onboarding_completed_at: Time.current)
          render json: { status: "submitted" }
        end

        private

        def hotel_params
          params.require(:hotel).permit(
            :name, :city, :country, :country_code, :latitude, :longitude,
            :description, :address, :certified, :wellness_standard
          )
        end
      end
    end
  end
end
