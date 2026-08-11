class Experience < ApplicationRecord
  KINDS = %w[wellness spiritual liderazgo_mujeres constelaciones_familiares breathwork neurociencia kabbalah mindfulness].freeze
  STATUSES = %w[draft active upcoming closed].freeze

  belongs_to :hotel
  has_many :bookings, dependent: :restrict_with_error

  before_validation :generate_slug, on: :create

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :commission_rate, numericality: { in: 0..1 }

  scope :published, -> { where(status: %w[active upcoming]) }
  scope :by_kind, ->(kind) {
    next all if kind.blank?
    values = Array(kind).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?)
    values.length == 1 ? where(kind: values.first) : where(kind: values)
  }
  scope :in_country, ->(code) {
    next all if code.blank?
    values = Array(code).flat_map { |v| v.to_s.split(",") }.map { |v| v.strip.upcase }.reject(&:blank?)
    values.length == 1 ? where(country_code: values.first) : where(country_code: values)
  }
  scope :in_enabled_country, -> { where(country_code: Country.enabled.select(:code)) }
  scope :available_between, ->(from, to) {
    next all if from.blank? || to.blank?
    where("starts_on <= ? AND ends_on >= ?", to, from)
  }
  scope :min_capacity, ->(guests) {
    next all if guests.blank?
    where("capacity IS NULL OR capacity >= ?", guests.to_i)
  }
  scope :search, ->(q) {
    next all if q.blank?

    term = "%#{sanitize_sql_like(q)}%"
    where("title ILIKE :t OR location ILIKE :t OR country ILIKE :t", t: term)
  }

  def price
    price_cents / 100.0
  end

  def commission_percent
    (commission_rate * 100).round
  end

  private

  def generate_slug
    return if slug.present? || title.blank?

    base = title.parameterize
    candidate = base
    i = 2
    while Experience.exists?(slug: candidate)
      candidate = "#{base}-#{i}"
      i += 1
    end
    self.slug = candidate
  end
end
