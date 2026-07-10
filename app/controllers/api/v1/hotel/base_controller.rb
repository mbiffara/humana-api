# Base controller for hotel-scoped endpoints. Ensures the authenticated user
# belongs to a hotel-kind organization and provides access to the hotel record.
module Api
  module V1
    module Hotel
      class BaseController < Api::V1::BaseController
        before_action :require_hotel!

        private

        def current_hotel
          @current_hotel ||= current_organization.hotels.first
        end

        def require_hotel!
          render_forbidden("Hotel access required") unless current_organization&.hotel?
        end
      end
    end
  end
end
