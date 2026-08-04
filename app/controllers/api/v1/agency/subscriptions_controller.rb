module Api
  module V1
    module Agency
      class SubscriptionsController < BaseController
        # GET /api/v1/agency/subscription/plans
        def plans
          plans = SubscriptionPlan.where(target_audience: "agency", active: true).order(:position)
          render json: { plans: plans.map { |p| ApiSerializers.subscription_plan(p) } }
        end

        # GET /api/v1/agency/subscription
        def show
          sub = current_organization.subscriptions.includes(:subscription_plan).order(created_at: :desc).first
          render json: { subscription: sub ? ApiSerializers.subscription(sub) : nil }
        end

        # POST /api/v1/agency/subscription
        def create
          plan = SubscriptionPlan.find(params[:plan_id])
          service = SubscriptionService.new(current_organization)

          result = service.create(
            plan,
            success_url: "#{web_url}/agency/settings?tab=subscription&stripe=success",
            cancel_url: "#{web_url}/agency/settings?tab=subscription&stripe=cancelled"
          )

          if result.checkout_url
            render json: { checkout_url: result.checkout_url }
          else
            render json: { subscription: ApiSerializers.subscription(result.subscription) }, status: :created
          end
        end

        # PUT /api/v1/agency/subscription
        def update
          plan = SubscriptionPlan.find(params[:plan_id])
          service = SubscriptionService.new(current_organization)

          result = service.update_plan(
            plan,
            success_url: "#{web_url}/agency/settings?tab=subscription&stripe=success",
            cancel_url: "#{web_url}/agency/settings?tab=subscription&stripe=cancelled"
          )

          if result.checkout_url
            render json: { checkout_url: result.checkout_url }
          else
            render json: { subscription: ApiSerializers.subscription(result.subscription) }
          end
        end

        # DELETE /api/v1/agency/subscription
        def destroy
          service = SubscriptionService.new(current_organization)
          sub = service.cancel
          render json: { subscription: ApiSerializers.subscription(sub) }
        end

        private

        def web_url
          ENV.fetch("HUMANA_WEB_URL", "http://localhost:3000")
        end
      end
    end
  end
end
