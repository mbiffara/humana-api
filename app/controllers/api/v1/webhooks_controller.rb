module Api
  module V1
    # Handles Stripe webhook events for subscription lifecycle.
    # No JWT auth — verified via Stripe signature when STRIPE_WEBHOOK_SECRET is set.
    class WebhooksController < ApplicationController
      skip_before_action :authenticate_user!, raise: false

      # POST /api/v1/webhooks/stripe
      def stripe
        payload = request.body.read
        event = construct_event(payload)
        return render json: { error: "Invalid signature" }, status: :bad_request unless event

        case event.type
        when "checkout.session.completed"
          handle_checkout_completed(event.data.object)
        when "customer.subscription.updated"
          handle_subscription_updated(event.data.object)
        when "customer.subscription.deleted"
          handle_subscription_deleted(event.data.object)
        when "invoice.payment_succeeded"
          handle_invoice_succeeded(event.data.object)
        when "invoice.payment_failed"
          handle_invoice_failed(event.data.object)
        end

        head :ok
      end

      private

      def construct_event(payload)
        secret = ENV["STRIPE_WEBHOOK_SECRET"]
        if secret.present?
          sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
          Stripe::Webhook.construct_event(payload, sig_header, secret)
        else
          # Dev mode: trust the payload without signature verification
          Stripe::Event.construct_from(JSON.parse(payload, symbolize_names: true))
        end
      rescue Stripe::SignatureVerificationError, JSON::ParserError
        nil
      end

      # Stripe Checkout completed — create/activate the subscription in our DB.
      def handle_checkout_completed(session)
        org_id = session.metadata&.organization_id
        plan_id = session.metadata&.plan_id
        return unless org_id && plan_id

        organization = Organization.find_by(id: org_id)
        plan = SubscriptionPlan.find_by(id: plan_id)
        return unless organization && plan

        stripe_sub = Stripe::Subscription.retrieve(session.subscription)

        # Cancel any previous active subscription in our DB (not in Stripe)
        organization.subscriptions.where(status: %w[active trialing]).update_all(
          status: "cancelled", cancelled_at: Time.current
        )

        sub = organization.subscriptions.create!(
          subscription_plan: plan,
          status: stripe_sub.status == "trialing" ? "trialing" : "active",
          stripe_subscription_id: stripe_sub.id,
          stripe_customer_id: stripe_sub.customer,
          current_period_start: Time.at(stripe_sub.current_period_start),
          current_period_end: Time.at(stripe_sub.current_period_end),
          trial_ends_at: stripe_sub.trial_end ? Time.at(stripe_sub.trial_end) : nil
        )

        SubscriptionMailer.confirmed(sub).deliver_later
      end

      # Subscription status changed in Stripe (upgrade, downgrade, past_due, etc.)
      def handle_subscription_updated(stripe_sub)
        sub = Subscription.find_by(stripe_subscription_id: stripe_sub.id)
        return unless sub

        new_status = map_stripe_status(stripe_sub.status)
        sub.update!(
          status: new_status,
          current_period_start: Time.at(stripe_sub.current_period_start),
          current_period_end: Time.at(stripe_sub.current_period_end)
        )
      end

      # Subscription cancelled/deleted in Stripe.
      def handle_subscription_deleted(stripe_sub)
        sub = Subscription.find_by(stripe_subscription_id: stripe_sub.id)
        return unless sub

        sub.update!(status: "cancelled", cancelled_at: Time.current)
        SubscriptionMailer.cancelled(sub).deliver_later
      end

      # Monthly invoice paid successfully — renewal confirmation.
      def handle_invoice_succeeded(invoice)
        return if invoice.billing_reason == "subscription_create" # Already handled in checkout

        sub = Subscription.find_by(stripe_subscription_id: invoice.subscription)
        return unless sub

        stripe_sub = Stripe::Subscription.retrieve(invoice.subscription)
        sub.update!(
          status: "active",
          current_period_start: Time.at(stripe_sub.current_period_start),
          current_period_end: Time.at(stripe_sub.current_period_end)
        )

        SubscriptionMailer.renewed(sub).deliver_later
      end

      # Payment failed — mark as past_due and notify.
      def handle_invoice_failed(invoice)
        sub = Subscription.find_by(stripe_subscription_id: invoice.subscription)
        return unless sub

        sub.update!(status: "past_due")
        SubscriptionMailer.payment_failed(sub).deliver_later
      end

      def map_stripe_status(stripe_status)
        case stripe_status
        when "active" then "active"
        when "trialing" then "trialing"
        when "past_due" then "past_due"
        when "canceled", "cancelled" then "cancelled"
        when "unpaid", "incomplete_expired" then "expired"
        else "active"
        end
      end
    end
  end
end
