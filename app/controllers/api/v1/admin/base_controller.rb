# Admin namespace base controller.
# Enforces platform admin access for all admin endpoints.
# All controllers under Api::V1::Admin inherit from this.
module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        before_action :require_admin!
      end
    end
  end
end
