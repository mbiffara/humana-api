module Api
  module V1
    module Agency
      class ProfileController < BaseController
        # GET /api/v1/agency/profile
        def show
          render json: { organization: ApiSerializers.organization(current_organization, include_onboarding: true) }
        end

        # PATCH /api/v1/agency/profile
        def update
          permitted = params.require(:organization).permit(
            :name, :legal_name, :phone, :primary_contact, :city, :country,
            :country_code, :website, :contact_email, :description
          )
          current_organization.update!(permitted)
          # Mark onboarding as completed when agency submits their profile
          current_organization.update!(onboarding_completed_at: Time.current) unless current_organization.onboarding_completed?
          render json: { organization: ApiSerializers.organization(current_organization, include_onboarding: true) }
        end
      end
    end
  end
end
