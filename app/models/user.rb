class User < ApplicationRecord
  has_secure_password

  ROLES = %w[owner member admin].freeze
  LOCALES = %w[en es pt].freeze

  belongs_to :organization

  before_validation { self.email = email.to_s.strip.downcase.presence }

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }
  validates :locale, inclusion: { in: LOCALES }
  validates :password, length: { minimum: 8 }, allow_nil: true

  delegate :agency?, :hotel?, to: :organization, allow_nil: true

  def platform_admin?
    role == "admin" || organization&.admin?
  end

  def touch_login!
    update_column(:last_login_at, Time.current)
  end
end
