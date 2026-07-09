# Magic-link invitation for new users.
# Created by admins, accepted by the invitee via a public endpoint.
# Token is auto-generated; link expires after 48 hours.
class Invitation < ApplicationRecord
  belongs_to :organization
  belongs_to :invited_by, class_name: "User"

  before_validation :generate_token, on: :create
  before_validation :set_expiry, on: :create

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: User::ROLES }
  validates :token, presence: true, uniqueness: true

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where(accepted_at: nil).where("expires_at <= ?", Time.current) }

  # Full URL the invitee clicks in the email.
  def magic_link
    base = ENV.fetch("HUMANA_WEB_URL", "http://localhost:3000")
    "#{base}/accept-invite?token=#{token}"
  end

  def expired?
    expires_at <= Time.current
  end

  def accepted?
    accepted_at.present?
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiry
    self.expires_at ||= 7.days.from_now
  end
end
