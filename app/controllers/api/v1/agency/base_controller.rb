module Api
  module V1
    module Agency
      class BaseController < Api::V1::BaseController
        before_action :require_agency!
      end
    end
  end
end
