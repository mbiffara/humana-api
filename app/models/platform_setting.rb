# Singleton model for platform-wide configuration. Access via
# PlatformSetting.current — creates the default row on first access.
class PlatformSetting < ApplicationRecord
  validates :platform_name, presence: true
  validates :support_email, presence: true
  validates :default_currency, presence: true, length: { is: 3 }
  validates :default_language, presence: true, length: { is: 2 }
  validates :agency_commission_rate, numericality: { in: 0..1 }
  validates :office_fee_rate, numericality: { in: 0..1 }
  validates :hotel_net_rate, numericality: { in: 0..1 }

  # Returns the singleton settings row, creating it with defaults if missing.
  def self.current
    first || create!
  end

  # Commission split for a given plan tier. Falls back to platform default.
  def agency_commission_percent
    (agency_commission_rate * 100).round
  end

  def office_fee_percent
    (office_fee_rate * 100).round
  end
end
