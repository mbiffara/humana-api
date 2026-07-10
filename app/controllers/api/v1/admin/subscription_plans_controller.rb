# Admin CRUD for subscription plans (Starter, Professional, Enterprise).
# Plans define pricing, features, and commission rates per tier.
module Api
  module V1
    module Admin
      class SubscriptionPlansController < BaseController
        def index
          scope = SubscriptionPlan.all
          scope = scope.active if params[:active] == "true"
          scope = scope.for_audience(params[:target_audience]) if params[:target_audience].present?

          plans = scope.ordered
          render json: { subscription_plans: plans.map { |p| ApiSerializers.subscription_plan(p) } }
        end

        def show
          plan = SubscriptionPlan.find(params[:id])
          render json: { subscription_plan: ApiSerializers.subscription_plan(plan) }
        end

        def create
          plan = SubscriptionPlan.new(plan_params)
          if plan.save
            render json: { subscription_plan: ApiSerializers.subscription_plan(plan) }, status: :created
          else
            render_unprocessable(plan.errors.full_messages)
          end
        end

        def update
          plan = SubscriptionPlan.find(params[:id])
          if plan.update(plan_params)
            render json: { subscription_plan: ApiSerializers.subscription_plan(plan) }
          else
            render_unprocessable(plan.errors.full_messages)
          end
        end

        def destroy
          plan = SubscriptionPlan.find(params[:id])
          plan.destroy!
          head :no_content
        rescue ActiveRecord::DeleteRestrictionError
          render json: { error: "Cannot delete plan with active subscriptions" }, status: :conflict
        end

        private

        def plan_params
          params.require(:subscription_plan).permit(
            :name, :slug, :price_cents, :currency, :billing_interval,
            :commission_rate, :stripe_price_id, :active, :trial_days,
            :position, :target_audience, features: {}
          )
        end
      end
    end
  end
end
