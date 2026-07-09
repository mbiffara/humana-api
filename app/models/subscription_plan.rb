# Subscription tier for the HUMANA platform (Starter, Professional, Enterprise).
# Defines monthly/yearly pricing, feature set, and the commission rate applied
# to bookings for agencies on this plan.
class SubscriptionPlan < ApplicationRecord
  BILLING_INTERVALS = %w[monthly yearly].freeze
  TARGET_AUDIENCES = %w[agency hotel].freeze

  has_many :subscriptions, dependent: :restrict_with_error

  before_validation :generate_slug, on: :create

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :billing_interval, inclusion: { in: BILLING_INTERVALS }
  validates :commission_rate, numericality: { in: 0..1 }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :target_audience, inclusion: { in: TARGET_AUDIENCES }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :for_audience, ->(a) { a.present? ? where(target_audience: a) : all }
  scope :ordered, -> { order(position: :asc) }

  def price
    price_cents / 100.0
  end

  def commission_percent
    (commission_rate * 100).round
  end

  private

  def generate_slug
    return if slug.present? || name.blank?
    self.slug = name.parameterize
  end
end
