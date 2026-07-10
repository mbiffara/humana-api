# Admin view of all organization subscriptions across the platform.
module Api
  module V1
    module Admin
      class SubscriptionsController < BaseController
        def index
          scope = Subscription.includes(:organization, :subscription_plan)
          scope = scope.by_status(params[:status]) if params[:status].present?

          subs = paginate(scope.order(created_at: :desc))
          render json: {
            subscriptions: subs.map { |s| ApiSerializers.subscription(s) },
            meta: meta_for(scope)
          }
        end

        def show
          sub = Subscription.find(params[:id])
          render json: { subscription: ApiSerializers.subscription(sub) }
        end
      end
    end
  end
end
