module Api
  module V1
    # Base for all authenticated v1 endpoints. Subclasses can skip the
    # before_action for public routes (e.g. login, public experience listing).
    class BaseController < ApplicationController
      before_action :authenticate_user!

      private

      def current_organization
        current_user&.organization
      end

      def page
        params.fetch(:page, 1).to_i.clamp(1, 10_000)
      end

      def per_page
        params.fetch(:per_page, 20).to_i.clamp(1, 100)
      end

      def paginate(scope)
        scope.limit(per_page).offset((page - 1) * per_page)
      end

      def meta_for(scope)
        total = scope.count
        { page: page, per_page: per_page, total: total,
          total_pages: (total.to_f / per_page).ceil }
      end
    end
  end
end
