# Base controller for hotel-scoped endpoints. Ensures the authenticated user
# belongs to a hotel-kind organization and provides access to the hotel record.
module Api
  module V1
    module Hotel
      class BaseController < Api::V1::BaseController
        before_action :require_hotel!
        before_action :require_hotel_record!

        private

        def current_hotel
          @current_hotel ||= current_organization.hotels.first
        end

        def require_hotel!
          render_forbidden("Hotel access required") unless current_organization&.hotel?
        end

        # Hotel orgs have no Hotel record until onboarding creates one; every
        # endpoint except the profile (which builds it) needs one to scope by.
        # Without this guard those endpoints would 500 on a nil current_hotel.
        def require_hotel_record!
          render_forbidden("Hotel profile is not set up yet") if current_hotel.nil?
        end
      end
    end
  end
end
