# Active subscription linking an organization to its chosen plan. Tracks
# Stripe lifecycle and billing periods. One active subscription per organization.
class Subscription < ApplicationRecord
  STATUSES = %w[trialing active past_due cancelled expired].freeze

  belongs_to :organization
  belongs_to :subscription_plan

  validates :status, inclusion: { in: STATUSES }
  validates :stripe_subscription_id, uniqueness: true, allow_nil: true

  scope :active_or_trialing, -> { where(status: %w[trialing active]) }
  scope :by_status, ->(s) { s.present? ? where(status: s) : all }

  delegate :name, :commission_rate, :commission_percent, :features,
           to: :subscription_plan, prefix: :plan

  def active?
    status.in?(%w[trialing active])
  end

  def trialing?
    status == "trialing"
  end

  def days_remaining_in_trial
    return 0 unless trialing? && trial_ends_at
    [(trial_ends_at.to_date - Date.current).to_i, 0].max
  end
end
