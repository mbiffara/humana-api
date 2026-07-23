class Hotel < ApplicationRecord
  belongs_to :organization
  has_many :experiences, dependent: :destroy
  has_many :room_types, dependent: :destroy
  has_many :rooms, dependent: :destroy
  has_many :availability_blocks, dependent: :destroy
  has_many :retreats, dependent: :destroy
  has_many :hotel_amenities, dependent: :destroy
  has_many :hotel_images, dependent: :destroy

  validates :name, presence: true
  validates :stars, numericality: { in: 1..5 }, allow_nil: true

  scope :certified, -> { where(certified: true) }
  scope :in_country, ->(code) { code.present? ? where(country_code: code.upcase) : all }
  scope :onboarded, -> { where.not(onboarding_completed_at: nil) }
  scope :in_enabled_country, -> { where(country_code: Country.enabled.select(:code)) }
  scope :search, ->(q) {
    next all if q.blank?

    term = "%#{sanitize_sql_like(q)}%"
    where("name ILIKE :t OR city ILIKE :t OR country ILIKE :t", t: term)
  }

  def onboarding_completed?
    onboarding_completed_at.present?
  end

  def cover_image
    hotel_images.covers.ordered.first
  end
end
