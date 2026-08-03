module Api
  module V1
    module Hotel
      class SubscriptionsController < BaseController
        skip_before_action :require_hotel_record!

        # GET /api/v1/hotel/subscription/plans
        def plans
          plans = SubscriptionPlan.where(target_audience: "hotel", active: true).order(:position)
          render json: { plans: plans.map { |p| ApiSerializers.subscription_plan(p) } }
        end

        # GET /api/v1/hotel/subscription
        def show
          sub = current_organization.subscriptions.includes(:subscription_plan).order(created_at: :desc).first
          render json: { subscription: sub ? ApiSerializers.subscription(sub) : nil }
        end

        # POST /api/v1/hotel/subscription
        def create
          plan = SubscriptionPlan.find(params[:plan_id])

          sub = current_organization.subscriptions.find_or_initialize_by(status: %w[active trialing])
          if sub.new_record?
            sub = current_organization.subscriptions.build
          end

          sub.subscription_plan = plan
          sub.status = "active"
          sub.current_period_start = Time.current
          sub.current_period_end = 1.month.from_now
          sub.save!

          render json: { subscription: ApiSerializers.subscription(sub) }, status: :created
        end
      end
    end
  end
end
