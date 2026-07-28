class Booking < ApplicationRecord
  STATUSES = %w[inquiry confirmed cancelled completed].freeze

  belongs_to :organization # the booking agency
  belongs_to :experience
  belongs_to :client, optional: true
  belongs_to :room_type, optional: true # accommodation category chosen by the agency
  belongs_to :room, optional: true      # specific room assigned by the hotel

  before_validation :assign_reference, on: :create
  before_validation :snapshot_dates, on: :create
  before_validation :infer_room_type_from_room
  before_validation :compute_amounts

  validates :reference, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :guests, numericality: { greater_than: 0 }
  validate :client_belongs_to_organization
  validate :room_type_belongs_to_experience_hotel
  validate :room_belongs_to_room_type

  scope :active, -> { where.not(status: "cancelled") }

  def amount
    amount_cents / 100.0
  end

  def commission
    commission_cents / 100.0
  end

  private

  def assign_reference
    return if reference.present?

    loop do
      candidate = "HMN-#{SecureRandom.alphanumeric(6).upcase}"
      next if Booking.exists?(reference: candidate)

      self.reference = candidate
      break
    end
  end

  def snapshot_dates
    self.starts_on ||= experience&.starts_on
    self.ends_on ||= experience&.ends_on
  end

  # Total = per-guest price * guests; commission derived from the experience rate.
  def compute_amounts
    return unless experience

    # Inherit the experience currency unless the caller explicitly set one —
    # the column's "USD" default must not mislabel non-USD experiences.
    if currency.blank? || (new_record? && !will_save_change_to_currency?)
      self.currency = experience.currency
    end
    self.amount_cents = experience.price_cents * guests if amount_cents.to_i.zero?
    self.commission_cents = (amount_cents * experience.commission_rate).round
  end

  def client_belongs_to_organization
    return if client.nil?

    errors.add(:client, "must belong to the booking organization") if client.organization_id != organization_id
  end

  def infer_room_type_from_room
    self.room_type ||= room&.room_type
  end

  def room_type_belongs_to_experience_hotel
    return if room_type.nil? || experience.nil?

    if room_type.hotel_id != experience.hotel_id
      errors.add(:room_type, "must belong to the experience's hotel")
    elsif room_type.status != "active" && (new_record? || will_save_change_to_room_type_id?)
      # Draft/inactive types are retired from sale; only newly selected room
      # types are checked so existing booking history stays valid.
      errors.add(:room_type, "is not open for sale")
    end
  end

  def room_belongs_to_room_type
    return if room.nil? || room_type.nil?

    errors.add(:room, "must belong to the selected room type") if room.room_type_id != room_type.id
  end
end
