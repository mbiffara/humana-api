# Enabled countries for the HUMANA platform. Maps organizations to regions
# and provides a canonical reference for ISO country codes, currencies, and flags.
class Country < ApplicationRecord
  STATUSES = %w[active inactive].freeze
  REGIONS = %w[LATAM Europe APAC North\ America Africa Middle\ East].freeze

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true, length: { is: 2 }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :enabled, -> { where(enabled: true) }
  scope :by_region, ->(r) { r.present? ? where(region: r) : all }
  scope :search, ->(q) {
    next all if q.blank?
    term = "%#{sanitize_sql_like(q)}%"
    where("name ILIKE :t OR code ILIKE :t", t: term)
  }

  before_validation do
    self.code = code.to_s.strip.upcase.presence
    self.name = name.to_s.strip.split(/\s+/).map(&:capitalize).join(" ").presence if name.present?
  end

  def display_name
    [flag_emoji, name].compact.join(" ")
  end
end
