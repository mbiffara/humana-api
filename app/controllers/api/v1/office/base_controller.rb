module Api
  module V1
    module Office
      class BaseController < Api::V1::BaseController
        before_action :require_office!

        private

        def require_office!
          render_forbidden unless current_organization&.office?
        end

        # Organizations assigned to this office OR sharing the same country_code,
        # excluding admin and other office orgs.
        def regional_organizations
          Organization
            .where(assigned_office_id: current_organization.id)
            .or(Organization.where(country_code: current_organization.country_code))
            .where.not(kind: %w[admin office])
        end

        def regional_hotel_organizations
          regional_organizations.where(kind: "hotel")
        end

        def regional_agency_organizations
          regional_organizations.where(kind: "agency")
        end

        def regional_hotels
          ::Hotel.where(organization_id: regional_hotel_organizations.select(:id))
        end

        def regional_bookings
          ::Booking.where(organization_id: regional_agency_organizations.select(:id))
        end

        def regional_retreats
          ::Retreat.where(hotel_id: regional_hotels.select(:id))
        end

        def office_fee_rate
          PlatformSetting.current&.office_fee_rate || 0.02
        end
      end
    end
  end
end
