# A shared space a hotel can offer to a retreat group: a hall, a yoga or
# meditation room, an auditorium, a terrace, a garden. Capacity is declared
# per layout because the same room seats a very different number of people
# as an auditorium than as a banquet.
class CommonSpace < ApplicationRecord
  SPACE_TYPES = %w[
    salon yoga_room meditation_room auditorium terrace garden outdoor
    meeting_room restaurant other
  ].freeze

  FLOOR_TYPES = %w[floating wood ceramic other].freeze

  EQUIPMENT = %w[
    projector screen sound microphones wifi air_conditioning chairs tables
    yoga_mats lighting other
  ].freeze

  CAPACITY_FIELDS = %i[
    capacity_seated capacity_yoga capacity_auditorium capacity_banquet
    capacity_workshop
  ].freeze

  # Optional text the form clears by submitting an empty string — store nil so
  # the `allow_nil` inclusion rules below still apply.
  BLANK_TO_NIL_FIELDS = %i[
    space_type_other floor_type floor_type_other equipment_other
  ].freeze

  belongs_to :hotel
  has_many :common_space_images, dependent: :destroy

  before_validation :nullify_blank_optional_text
  before_validation :normalize_equipment

  validates :name, presence: true, length: { maximum: 120 }
  validates :space_type, inclusion: { in: SPACE_TYPES }
  validates :floor_type, inclusion: { in: FLOOR_TYPES }, allow_nil: true
  validates(*CAPACITY_FIELDS,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true)
  validates :area_sqm, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :space_type_other, presence: true, if: -> { space_type == "other" }
  validate :equipment_must_be_known

  scope :ordered, -> { order(position: :asc, id: :asc) }

  # The flagged primary, falling back to the first photo so a space with a
  # gallery always has a thumbnail.
  def primary_image
    images = common_space_images.to_a
    images.find(&:is_primary) || images.min_by { |img| [img.position, img.id] }
  end

  private

  def nullify_blank_optional_text
    BLANK_TO_NIL_FIELDS.each do |field|
      value = self[field]
      self[field] = nil if value.is_a?(String) && value.strip.empty?
    end
  end

  def normalize_equipment
    self.equipment = Array(equipment).compact_blank
  end

  def equipment_must_be_known
    values = Array(equipment)
    unknown = values - EQUIPMENT
    errors.add(:equipment, "contains unknown values: #{unknown.uniq.join(', ')}") if unknown.any?
    errors.add(:equipment, "contains duplicate values") if values.length != values.uniq.length
  end
end
