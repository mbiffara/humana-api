module Api
  module V1
    module Office
      class ProfilesController < BaseController
        # GET /api/v1/office/profile
        def show
          render json: { organization: ApiSerializers.organization(current_organization, include_onboarding: true) }
        end

        # PATCH /api/v1/office/profile
        def update
          permitted = params.require(:organization).permit(
            :name, :phone, :primary_contact, :address, :city, :country,
            :country_code, :contact_email
          )
          current_organization.update!(permitted)
          current_user.update!(name: params[:user_name]) if params[:user_name].present?
          current_organization.update!(onboarding_completed_at: Time.current) unless current_organization.onboarding_completed?
          render json: { organization: ApiSerializers.organization(current_organization, include_onboarding: true) }
        end
      end
    end
  end
end
