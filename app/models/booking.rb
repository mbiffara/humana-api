class Booking < ApplicationRecord
  STATUSES = %w[inquiry confirmed cancelled completed].freeze

  belongs_to :organization # the booking agency
  belongs_to :experience
  belongs_to :client, optional: true

  before_validation :assign_reference, on: :create
  before_validation :snapshot_dates, on: :create
  before_validation :compute_amounts

  validates :reference, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :guests, numericality: { greater_than: 0 }
  validate :client_belongs_to_organization

  scope :active, -> { where.not(status: "cancelled") }

  def amount
    amount_cents / 100.0
  end

  def commission
    commission_cents / 100.0
  end

  private

  def assign_reference
    return if reference.present?

    loop do
      candidate = "HMN-#{SecureRandom.alphanumeric(6).upcase}"
      next if Booking.exists?(reference: candidate)

      self.reference = candidate
      break
    end
  end

  def snapshot_dates
    self.starts_on ||= experience&.starts_on
    self.ends_on ||= experience&.ends_on
  end

  # Total = per-guest price * guests; commission derived from the experience rate.
  def compute_amounts
    return unless experience

    self.currency = experience.currency if currency.blank?
    self.amount_cents = experience.price_cents * guests if amount_cents.to_i.zero?
    self.commission_cents = (amount_cents * experience.commission_rate).round
  end

  def client_belongs_to_organization
    return if client.nil?

    errors.add(:client, "must belong to the booking organization") if client.organization_id != organization_id
  end
end
