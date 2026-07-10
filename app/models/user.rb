class User < ApplicationRecord
  has_secure_password

  ROLES = %w[owner member admin].freeze
  STATUSES = %w[pending active suspended rejected].freeze
  LOCALES = %w[en es pt].freeze

  belongs_to :organization

  before_validation { self.email = email.to_s.strip.downcase.presence }

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }
  validates :locale, inclusion: { in: LOCALES }
  validates :password, length: { minimum: 8 }, allow_nil: true

  scope :by_status, ->(s) { where(status: s) if s.present? }
  scope :search, ->(q) { where("name ILIKE :q OR email ILIKE :q", q: "%#{q}%") if q.present? }

  delegate :agency?, :hotel?, to: :organization, allow_nil: true

  def platform_admin?
    role == "admin" || organization&.admin?
  end

  def touch_login!
    update_column(:last_login_at, Time.current)
  end

  def onboarding_completed?
    onboarding_completed_at.present?
  end

  def complete_onboarding!
    update_column(:onboarding_completed_at, Time.current)
  end
end
