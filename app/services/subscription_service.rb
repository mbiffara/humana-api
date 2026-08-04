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
      Stripe::Subscription.cancel(sub.stripe_subscription_id)
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
    sub
  end

  def create_checkout_session(plan, success_url:, cancel_url:)
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

  def find_or_create_stripe_customer
    # Reuse existing customer from previous subscriptions
    existing_sub = @organization.subscriptions.where.not(stripe_customer_id: [nil, ""]).order(created_at: :desc).first
    if existing_sub
      return Stripe::Customer.retrieve(existing_sub.stripe_customer_id)
    end

    Stripe::Customer.create(
      email: @organization.contact_email || @organization.users.find_by(role: "owner")&.email,
      name: @organization.name,
      metadata: { organization_id: @organization.id }
    )
  end
end
