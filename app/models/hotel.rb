class Hotel < ApplicationRecord
  PROPERTY_TYPES = %w[hotel resort retreat_center eco_lodge boutique_hotel villa hacienda other].freeze
  ENVIRONMENTS = %w[countryside beach jungle urban mountain hills island].freeze
  AIRPORT_TRANSFERS = %w[none included paid].freeze

  # "flexible" is a sentinel the onboarding form offers next to a 24h time.
  TIME_FORMAT = /\A(?:flexible|(?:[01]\d|2[0-3]):[0-5]\d)\z/

  belongs_to :organization
  has_many :experiences, dependent: :destroy
  has_many :room_types, dependent: :destroy
  has_many :rooms, dependent: :destroy
  has_many :availability_blocks, dependent: :destroy
  has_many :retreats, dependent: :destroy
  has_many :hotel_amenities, dependent: :destroy
  has_many :hotel_images, dependent: :destroy

  # Optional text the onboarding form clears by submitting an empty string —
  # store nil so the `allow_nil` format/inclusion rules below still apply.
  BLANK_TO_NIL_FIELDS = %i[
    check_in_time check_out_time
    city country country_code
    state_region instagram nearest_airport
    airport_transfer airport_transfer_notes
    property_type property_type_other
    pet_size_restriction_notes pet_extra_cost_notes
    website phone contact_email postal_code address description
  ].freeze

  before_validation :nullify_blank_optional_text
  before_validation :normalize_environments
  before_validation :clear_property_type_other_unless_other
  before_validation :clear_pet_policy_unless_friendly

  validates :name, presence: true

  # Location
  validates :check_in_time, :check_out_time, format: { with: TIME_FORMAT }, allow_nil: true
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validates :instagram, length: { maximum: 100 }, allow_nil: true
  validates :airport_distance_km, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :airport_time_min, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :distance_to_center_km, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :airport_transfer, inclusion: { in: AIRPORT_TRANSFERS }, allow_nil: true

  # Property type
  validates :property_type, inclusion: { in: PROPERTY_TYPES }, allow_nil: true
  validates :property_type_other, presence: true, if: -> { property_type == "other" }

  # Environments
  validate :environments_must_be_known

  # Pet policy
  validates :pet_size_restriction_notes, :pet_extra_cost_notes, length: { maximum: 200 }, allow_nil: true

  # Group size
  validates :group_min_guests, :group_max_guests,
            numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :group_max_not_below_min

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

  private

  def nullify_blank_optional_text
    BLANK_TO_NIL_FIELDS.each do |field|
      value = self[field]
      self[field] = nil if value.is_a?(String) && value.strip.empty?
    end
  end

  def normalize_environments
    self.environments = Array(environments).compact_blank.uniq
  end

  def environments_must_be_known
    unknown = Array(environments) - ENVIRONMENTS
    return if unknown.empty?

    errors.add(:environments, "contains unknown values: #{unknown.join(', ')}")
  end

  # The free-text label only makes sense alongside the "other" type.
  def clear_property_type_other_unless_other
    self.property_type_other = nil unless property_type == "other"
  end

  # A hotel that is not pet friendly carries no pet detail at all, and each
  # note only survives while its own flag is on.
  def clear_pet_policy_unless_friendly
    unless pet_friendly == true
      self.pet_dogs = nil
      self.pet_cats = nil
      self.pet_size_restriction = nil
      self.pet_size_restriction_notes = nil
      self.pet_extra_cost = nil
      self.pet_extra_cost_notes = nil
      self.pet_common_areas = nil
      self.pet_specific_rooms = nil
      return
    end

    self.pet_size_restriction_notes = nil unless pet_size_restriction == true
    self.pet_extra_cost_notes = nil unless pet_extra_cost == true
  end

  def group_max_not_below_min
    return if group_min_guests.blank? || group_max_guests.blank?
    return if group_max_guests >= group_min_guests

    errors.add(:group_max_guests, "must be greater than or equal to the minimum group size")
  end
end
