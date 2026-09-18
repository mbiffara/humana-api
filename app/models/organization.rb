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
  belongs_to :assigned_office, class_name: "Organization", optional: true

  # The only social networks the verification form offers. "other" is the
  # catch-all for a link that fits none of them.
  SOCIAL_LINK_KEYS = %w[instagram facebook linkedin tiktok youtube other].freeze

  # Verification text the form clears by posting an empty string — store nil
  # so a cleared field reads as absent rather than as an empty answer.
  BLANK_TO_NIL_FIELDS = %i[
    legal_name business_name tax_id primary_contact primary_contact_role
    commercial_registration website ownership_document_url
  ].freeze

  before_validation :nullify_blank_verification_text

  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }

  # Verification block (LOG-157): who legally owns or represents the property.
  validates :legal_name, :business_name, :primary_contact, :primary_contact_role,
            :commercial_registration,
            length: { maximum: 200 }, allow_blank: true
  validates :tax_id, length: { maximum: 60 }, allow_blank: true
  # A whole http(s) link, not a bare domain — the app renders it as an anchor.
  # Anchored at both ends so nothing can ride along after a newline. Only on
  # change: an organization that stored a bare domain before this rule existed
  # must still be able to save everything else, including the name the hotel
  # profile keeps in sync.
  validates :website, format: { with: %r{\Ahttps?://\S+\z}i },
                      allow_blank: true, if: :website_changed?
  validates :ownership_document_url, length: { maximum: 2000 }, allow_blank: true
  validate :social_links_must_be_known

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

  private

  def nullify_blank_verification_text
    BLANK_TO_NIL_FIELDS.each do |field|
      value = self[field]
      self[field] = nil if value.is_a?(String) && value.strip.empty?
    end

    return unless social_links.is_a?(Hash)

    self.social_links = social_links.reject { |_k, v| v.nil? || (v.is_a?(String) && v.strip.empty?) }
  end

  # A flat { network => url } hash, limited to the networks the form offers so
  # the app can render each one with its own icon.
  def social_links_must_be_known
    unless social_links.is_a?(Hash)
      errors.add(:social_links, "must be an object")
      return
    end

    unknown = social_links.keys.map(&:to_s) - SOCIAL_LINK_KEYS
    errors.add(:social_links, "contains unknown keys") if unknown.any?

    invalid = social_links.values.any? { |v| !v.is_a?(String) || v.length > 300 }
    errors.add(:social_links, "values must be strings up to 300 characters") if invalid
  end
end
