# Shared logic for creating, cancelling, and updating subscriptions
# with Stripe Billing integration. Used by both Hotel and Agency controllers.
class SubscriptionService
  Result = Struct.new(:subscription, :checkout_url, keyword_init: true)

  def initialize(organization)
    @organization = organization
  end

  # Select a plan: free plans activate directly, paid plans redirect to Stripe Checkout.
  def create(plan, success_url:, cancel_url:)
    if plan.price_cents.zero?
      sub = activate_free_plan(plan)
      Result.new(subscription: sub)
    else
      url = create_checkout_session(plan, success_url: success_url, cancel_url: cancel_url)
      Result.new(checkout_url: url)
    end
  end

  # Cancel the current active subscription in Stripe + DB.
  def cancel
    sub = current_subscription
    raise ActiveRecord::RecordNotFound, "No active subscription" unless sub

    if sub.stripe_subscription_id.present?
      begin
        Stripe::Subscription.cancel(sub.stripe_subscription_id)
      rescue Stripe::InvalidRequestError => e
        Rails.logger.warn("Stripe cancel failed (#{e.message}), cancelling locally only")
      end
    end

    sub.update!(status: "cancelled", cancelled_at: Time.current)
    SubscriptionMailer.cancelled(sub).deliver_later
    sub
  end

  # Change plan on an existing subscription.
  # If the current sub is Stripe-managed, update the subscription item in Stripe.
  # Otherwise (free → paid), create a new checkout session.
  def update_plan(new_plan, success_url:, cancel_url:)
    sub = current_subscription

    # No active sub — treat as new creation
    return create(new_plan, success_url: success_url, cancel_url: cancel_url) unless sub

    # Free plan selection — activate directly
    if new_plan.price_cents.zero?
      if sub.stripe_subscription_id.present?
        Stripe::Subscription.cancel(sub.stripe_subscription_id)
      end
      sub.update!(
        subscription_plan: new_plan,
        status: "active",
        stripe_subscription_id: nil,
        current_period_start: Time.current,
        current_period_end: 1.month.from_now
      )
      return Result.new(subscription: sub)
    end

    # Stripe-managed sub changing to a different paid plan
    if sub.stripe_subscription_id.present?
      stripe_sub = Stripe::Subscription.retrieve(sub.stripe_subscription_id)
      Stripe::Subscription.update(
        sub.stripe_subscription_id,
        items: [{
          id: stripe_sub.items.data.first.id,
          price: new_plan.stripe_price_id
        }],
        proration_behavior: "create_prorations"
      )
      sub.update!(subscription_plan: new_plan)
      return Result.new(subscription: sub)
    end

    # Free → paid upgrade: create checkout
    url = create_checkout_session(new_plan, success_url: success_url, cancel_url: cancel_url)
    Result.new(checkout_url: url)
  end

  # Verify a completed Stripe Checkout Session and create the subscription locally.
  # Called when the user returns from Stripe Checkout (no webhook needed).
  # Idempotent: safe to call multiple times with the same session_id.
  def verify_checkout_session(session_id)
    session = Stripe::Checkout::Session.retrieve(session_id)
    raise ActiveRecord::RecordNotFound, "Session not completed" unless session.status == "complete"

    plan_id = session.metadata&.plan_id
    plan = SubscriptionPlan.find(plan_id)
    stripe_sub_id = session.subscription

    # Already activated (e.g. via webhook or concurrent call) — just return it
    existing = @organization.subscriptions.find_by(stripe_subscription_id: stripe_sub_id)
    return existing if existing

    stripe_sub = Stripe::Subscription.retrieve(stripe_sub_id)

    # Use advisory lock to prevent concurrent verify calls from racing
    @organization.with_lock do
      # Re-check inside lock — another request may have created it
      existing = @organization.subscriptions.find_by(stripe_subscription_id: stripe_sub_id)
      return existing if existing

      # Cancel previous active subscriptions
      @organization.subscriptions.where(status: %w[active trialing]).update_all(
        status: "cancelled", cancelled_at: Time.current
      )

      sub = @organization.subscriptions.create!(
        subscription_plan: plan,
        status: stripe_sub.status == "trialing" ? "trialing" : "active",
        stripe_subscription_id: stripe_sub.id,
        stripe_customer_id: stripe_sub.customer,
        current_period_start: Time.at(stripe_sub.current_period_start),
        current_period_end: Time.at(stripe_sub.current_period_end),
        trial_ends_at: stripe_sub.trial_end ? Time.at(stripe_sub.trial_end) : nil
      )
      SubscriptionMailer.confirmed(sub).deliver_later
      sub
    end
  end

  private

  def current_subscription
    @organization.subscriptions.where(status: %w[active trialing]).order(created_at: :desc).first
  end

  def activate_free_plan(plan)
    sub = current_subscription
    if sub
      sub.update!(subscription_plan: plan, status: "active",
                  current_period_start: Time.current, current_period_end: 1.month.from_now)
    else
      sub = @organization.subscriptions.create!(
        subscription_plan: plan,
        status: "active",
        current_period_start: Time.current,
        current_period_end: 1.month.from_now
      )
    end
    SubscriptionMailer.confirmed(sub).deliver_later
    sub
  end

  def create_checkout_session(plan, success_url:, cancel_url:)
    ensure_stripe_price!(plan)
    customer = find_or_create_stripe_customer

    session = Stripe::Checkout::Session.create(
      customer: customer.id,
      mode: "subscription",
      line_items: [{ price: plan.stripe_price_id, quantity: 1 }],
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: {
        organization_id: @organization.id,
        plan_id: plan.id
      }
    )

    session.url
  end

  # Auto-create Stripe Product + Price if the plan is missing a stripe_price_id.
  # This handles cases where seeds ran before STRIPE_SECRET_KEY was configured.
  def ensure_stripe_price!(plan)
    return if plan.stripe_price_id.present?

    product = Stripe::Product.create(
      name: plan.name,
      metadata: { humana_plan_id: plan.id, target_audience: plan.target_audience }
    )

    interval = plan.billing_interval == "yearly" ? "year" : "month"
    price = Stripe::Price.create(
      product: product.id,
      unit_amount: plan.price_cents,
      currency: plan.currency.downcase,
      recurring: { interval: interval }
    )

    plan.update!(stripe_price_id: price.id)
  end

  def find_or_create_stripe_customer
    # Reuse existing customer from previous subscriptions
    existing_sub = @organization.subscriptions.where.not(stripe_customer_id: [nil, ""]).order(created_at: :desc).first
    if existing_sub
      begin
        return Stripe::Customer.retrieve(existing_sub.stripe_customer_id)
      rescue Stripe::InvalidRequestError
        # Customer no longer exists in Stripe — fall through to create a new one
      end
    end

    Stripe::Customer.create(
      email: @organization.contact_email || @organization.users.find_by(role: "owner")&.email,
      name: @organization.name,
      metadata: { organization_id: @organization.id }
    )
  end
end
