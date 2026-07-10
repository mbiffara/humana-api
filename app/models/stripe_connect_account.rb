# Stripe Connect account for hotel organizations receiving payouts.
# Tracks onboarding status and monthly recurring revenue.
class StripeConnectAccount < ApplicationRecord
  ONBOARDING_STATUSES = %w[pending in_progress complete restricted].freeze

  belongs_to :organization

  validates :stripe_account_id, presence: true, uniqueness: true
  validates :onboarding_status, inclusion: { in: ONBOARDING_STATUSES }
  validates :organization_id, uniqueness: true

  scope :complete, -> { where(onboarding_status: "complete") }
  scope :pending_onboarding, -> { where(onboarding_status: %w[pending in_progress]) }

  def complete?
    onboarding_status == "complete"
  end

  def mrr
    mrr_cents / 100.0
  end
end
