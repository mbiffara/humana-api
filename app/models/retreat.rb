# Full retreat program with day-by-day schedule, facilitators, inclusions,
# per-room pricing, and gallery images. Created by hotels, agencies, or offices.
class Retreat < ApplicationRecord
  TYPES = %w[wellness spiritual liderazgo_mujeres constelaciones_familiares breathwork neurociencia kabbalah mindfulness].freeze
  STATUSES = %w[draft pending_review active upcoming closed cancelled].freeze
  CREATOR_TYPES = %w[hotel agency office].freeze

  belongs_to :hotel
  belongs_to :created_by_organization, class_name: "Organization"

  has_many :bookings
  has_many :retreat_days, dependent: :destroy
  has_many :retreat_activities, through: :retreat_days
  has_many :retreat_facilitators, dependent: :destroy
  has_many :retreat_inclusions, dependent: :destroy
  has_many :retreat_pricings, dependent: :destroy
  has_many :retreat_images, dependent: :destroy

  before_validation :generate_slug, on: :create
  before_save :compute_min_price

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :retreat_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :created_by_type, inclusion: { in: CREATOR_TYPES }
  validates :duration_nights, numericality: { greater_than: 0 }
  validates :commission_rate, numericality: { in: 0..1 }

  scope :published, -> { where(status: %w[active upcoming]) }
  scope :by_type, ->(t) {
    next all if t.blank?
    values = Array(t).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?)
    values.length == 1 ? where(retreat_type: values.first) : where(retreat_type: values)
  }
  scope :by_status, ->(s) { s.present? ? where(status: s) : all }
  scope :in_country, ->(code) {
    next all if code.blank?
    values = Array(code).flat_map { |v| v.to_s.split(",") }.map { |v| v.strip.upcase }.reject(&:blank?)
    values.length == 1 ? where(country_code: values.first) : where(country_code: values)
  }
  scope :featured, -> { where(featured: true) }
  scope :certified, -> { where(certified: true) }
  scope :in_enabled_country, -> { where(country_code: Country.enabled.select(:code)) }
  scope :search, ->(q) {
    next all if q.blank?
    term = "%#{sanitize_sql_like(q)}%"
    where("name ILIKE :t OR location ILIKE :t OR country ILIKE :t OR description ILIKE :t", t: term)
  }

  def min_price
    min_price_cents / 100.0
  end

  def commission_percent
    (commission_rate * 100).round
  end

  def cover_image
    retreat_images.find_by(is_cover: true) || retreat_images.order(:position).first
  end

  def spots_available
    return capacity unless capacity.to_i > 0
    booked = bookings.where(status: %w[inquiry confirmed]).sum(:guests)
    [capacity - booked, 0].max
  end

  def publish!
    update!(status: "active", published_at: Time.current)
  end

  private

  def generate_slug
    return if slug.present? || name.blank?
    base = name.parameterize
    candidate = base
    i = 2
    while Retreat.exists?(slug: candidate)
      candidate = "#{base}-#{i}"
      i += 1
    end
    self.slug = candidate
  end

  # Cache the lowest per-guest price across all room types for quick display.
  # Falls back to cheapest hotel room × duration when no retreat-specific pricing exists.
  def compute_min_price
    lowest = retreat_pricings.minimum(:price_per_guest_cents)
    if lowest.nil? && hotel.present?
      cheapest_room = hotel.room_types.where(status: "active").minimum(:price_per_night_cents)
      lowest = cheapest_room ? cheapest_room * (duration_nights || 1) : nil
    end
    self.min_price_cents = lowest || 0
  end
end
