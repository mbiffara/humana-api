module Api
  module V1
    module Hotel
      class ProfilesController < BaseController
        # The profile endpoint is the one place a hotel org without a Hotel
        # record may go — updating it builds the record during onboarding.
        skip_before_action :require_hotel_record!

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
          # Keep organization name in sync with hotel name
          current_organization.update!(name: hotel.name) if hotel.name.present?
          current_user.update!(name: params[:user_name]) if params[:user_name].present?
          current_user.update!(phone: params[:user_phone]) if params[:user_phone].present?

          # Bank details (nested under organization key)
          if params[:organization].present?
            bank_attrs = params.require(:organization).permit(
              :bank_account_holder, :bank_iban, :bank_swift,
              :bank_currency, :bank_country
            )
            if bank_attrs.values.any?(&:present?)
              bank_attrs[:bank_status] = "configured"
              current_organization.update!(bank_attrs)
            end
          end

          render json: {
            hotel: ApiSerializers.hotel_full(hotel),
            organization: ApiSerializers.organization(current_organization.reload, include_onboarding: true)
          }
        end

        # POST /api/v1/hotel/profile/submit_for_review
        def submit_for_review
          current_organization.update!(
            onboarding_completed_at: Time.current,
            pending_changes: false,
            review_feedback: nil,
            review_feedback_at: nil
          )
          render json: { user: ApiSerializers.user(current_user.reload) }
        end

        private

        def hotel_params
          params.require(:hotel).permit(
            :name, :city, :country, :country_code, :latitude, :longitude,
            :description, :address, :certified, :wellness_standard,
            :phone, :stars, :check_in_time, :check_out_time, :total_rooms,
            :website, :contact_email, :postal_code, :logo_url
          )
        end
      end
    end
  end
end
