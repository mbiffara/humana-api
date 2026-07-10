module Api
  module V1
    module Office
      class BaseController < Api::V1::BaseController
        before_action :require_office!

        private

        def require_office!
          render_forbidden unless current_organization&.office?
        end
      end
    end
  end
end
