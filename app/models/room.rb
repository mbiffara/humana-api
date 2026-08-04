# A physical, individually numbered or named room within a hotel (e.g. "101",
# "Villa Azul"). Rooms belong to a RoomType, which defines category, capacity
# and nightly pricing. Auto-generated rooms are created to match the room
# type's total_rooms count and can be renamed by the hotel afterwards.
class Room < ApplicationRecord
  STATUSES = %w[available out_of_service].freeze

  belongs_to :hotel
  belongs_to :room_type
  has_many :bookings, dependent: :nullify

  validates :number, presence: true, uniqueness: { scope: :hotel_id, case_sensitive: false }
  validates :status, inclusion: { in: STATUSES }
  validate :room_type_belongs_to_hotel

  scope :bookable, -> { where(status: "available") }
  scope :by_room_type, ->(id) { id.present? ? where(room_type_id: id) : all }
  scope :by_status, ->(s) { s.present? ? where(status: s) : all }
  scope :ordered, -> { order(:number, :id) }

  private

  def room_type_belongs_to_hotel
    return if room_type.nil? || hotel.nil?

    errors.add(:room_type, "must belong to the same hotel") if room_type.hotel_id != hotel_id
  end
end
