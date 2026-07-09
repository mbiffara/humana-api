class Organization < ApplicationRecord
  KINDS = %w[hotel agency admin office].freeze
  STATUSES = %w[pending verified suspended].freeze

  has_many :users, dependent: :destroy
  has_many :hotels, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_one :stripe_connect_account, dependent: :destroy
  has_many :created_retreats, class_name: "Retreat", foreign_key: :created_by_organization_id, dependent: :nullify

  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }

  SPECIALTIES = %w[
    wellness corporate adventure spiritual yoga
    meditation detox fitness culinary nature
  ].freeze

  scope :hotels_kind, -> { where(kind: "hotel") }
  scope :agencies, -> { where(kind: "agency") }
  scope :offices, -> { where(kind: "office") }
  scope :verified, -> { where(status: "verified") }
  scope :onboarded, -> { where.not(onboarding_completed_at: nil) }
  scope :search, ->(q) {
    next all if q.blank?
    term = "%#{sanitize_sql_like(q)}%"
    where("name ILIKE :t OR city ILIKE :t OR contact_email ILIKE :t", t: term)
  }

  def agency?
    kind == "agency"
  end

  def hotel?
    kind == "hotel"
  end

  def admin?
    kind == "admin"
  end

  def office?
    kind == "office"
  end

  def onboarding_completed?
    onboarding_completed_at.present?
  end
end
