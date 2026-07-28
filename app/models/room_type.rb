# Room category within a hotel. Hotels may offer multiple room types (standard,
# superior, suite, villa) each with different capacity and nightly rates.
# Referenced by RetreatPricing for per-guest retreat pricing by room category.
class RoomType < ApplicationRecord
  CATEGORIES = %w[standard superior suite villa penthouse bungalow].freeze

  BED_TYPES = %w[single double queen king twin bunk sofa_bed].freeze

  STATUSES = %w[active draft inactive].freeze

  belongs_to :hotel
  has_many :retreat_pricings, dependent: :destroy
  has_many :room_images, dependent: :destroy
  has_many :room_rate_tiers, dependent: :destroy
  has_many :rooms, dependent: :destroy
  has_many :availability_blocks, dependent: :destroy
  # Bookings keep their history when a room type is retired; they just lose
  # the accommodation attribution (mirrors Room's nullify behavior).
  has_many :bookings, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :hotel_id }
  validates :category, inclusion: { in: CATEGORIES }
  validates :capacity, numericality: { greater_than: 0 }
  validates :price_per_night_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :bed_type, inclusion: { in: BED_TYPES }, allow_nil: true
  validates :status, inclusion: { in: STATUSES }

  scope :by_category, ->(c) { c.present? ? where(category: c) : all }
  scope :by_status, ->(s) { s.present? ? where(status: s) : all }
  scope :ordered, -> { order(position: :asc, price_per_night_cents: :asc) }

  after_save :sync_rooms_with_total, if: :saved_change_to_total_rooms?

  def price_per_night
    price_per_night_cents / 100.0
  end

  private

  # Keeps physical Room records in line with the declared total_rooms count.
  # Missing rooms are auto-created with sequential placeholder names the hotel
  # can rename later ("Suite 1", "Suite 2", ...). When the count shrinks, only
  # auto-generated rooms with no booking history are removed; if fewer can be
  # removed, total_rooms is corrected back to the real count.
  def sync_rooms_with_total
    target = total_rooms.to_i
    return if target.negative?

    current = rooms.count
    if current < target
      create_placeholder_rooms(target - current)
    elsif current > target
      rooms.where(auto_generated: true).where.missing(:bookings)
           .order(id: :desc).limit(current - target).destroy_all
      actual = rooms.count
      update_column(:total_rooms, actual) if actual != target
    end
  end

  def create_placeholder_rooms(count)
    taken = hotel.rooms.pluck(Arel.sql("lower(number)")).to_set
    seq = 0
    count.times do
      seq += 1
      seq += 1 while taken.include?("#{name} #{seq}".downcase)
      number = "#{name} #{seq}"
      rooms.create!(hotel: hotel, number: number, auto_generated: true)
      taken << number.downcase
    end
  end
end
