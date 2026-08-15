class Booking < ApplicationRecord
  STATUSES = %w[pending_payment inquiry confirmed cancelled completed].freeze

  belongs_to :organization # the booking agency
  belongs_to :experience, optional: true
  belongs_to :hotel, optional: true     # direct hotel booking (no experience)
  belongs_to :client, optional: true
  belongs_to :room_type, optional: true # accommodation category chosen by the agency
  belongs_to :room, optional: true      # specific room assigned by the hotel
  belongs_to :retreat, optional: true    # retreat this booking is for (agency-created retreats)

  validate :has_experience_or_hotel

  before_validation :assign_reference, on: :create
  before_validation :snapshot_dates, on: :create
  before_validation :infer_room_type_from_room
  before_validation :clear_mismatched_retreat, on: :create
  before_validation :default_guests_from_room_type, on: :create
  before_validation :compute_amounts

  validates :reference, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :guests, numericality: { greater_than: 0 }
  validate :client_belongs_to_organization
  validate :hotel_matches_experience
  validate :room_type_belongs_to_experience_hotel
  validate :room_belongs_to_room_type
  validate :room_type_has_availability, if: :availability_check_needed?
  before_save :reverify_availability_under_lock, if: :availability_check_needed?

  scope :active, -> { where.not(status: %w[cancelled pending_payment]) }
  # All bookings a hotel serves — via one of its experiences or booked
  # directly against the hotel (e.g. retreat bookings without an experience).
  # The experience is authoritative when present: bookings.hotel_id only
  # counts for experience-less bookings, so a mismatched hotel_id can never
  # expose a booking to another hotel's workspace.
  scope :for_hotel, ->(hotel) {
    left_joins(:experience).where(
      "experiences.hotel_id = :hotel_id OR " \
      "(bookings.experience_id IS NULL AND bookings.hotel_id = :hotel_id)",
      hotel_id: hotel.id
    )
  }

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
    if experience
      compute_experience_amounts
    elsif retreat && room_type
      compute_retreat_amounts
    elsif room_type && starts_on && ends_on
      compute_lodging_amounts
    end
  end

  def compute_experience_amounts
    if currency.blank? || (new_record? && !will_save_change_to_currency?)
      self.currency = experience.currency
    end
    self.amount_cents = experience.price_cents * guests if amount_cents.to_i.zero?
    self.commission_cents = (amount_cents * experience.commission_rate).round
  end

  # Retreat booking: flat per-guest price from retreat_pricings for the chosen room type.
  # Falls back to lodging calculation if no retreat pricing is configured.
  def compute_retreat_amounts
    pricing = retreat.retreat_pricings.find_by(room_type_id: room_type_id)
    if pricing
      self.currency = pricing.currency if currency.blank? || (new_record? && !will_save_change_to_currency?)
      self.amount_cents = pricing.price_per_guest_cents if amount_cents.to_i.zero?
      self.commission_cents = (amount_cents * retreat.commission_rate).round
    elsif starts_on && ends_on
      compute_lodging_amounts
    end
  end

  # Direct hotel booking: price from room_type * nights (per-room rate).
  # Commission from platform default rate.
  def compute_lodging_amounts
    nights = (ends_on - starts_on).to_i
    return if nights <= 0

    if currency.blank? || (new_record? && !will_save_change_to_currency?)
      self.currency = room_type.currency
    end
    if amount_cents.to_i.zero?
      self.amount_cents = room_type.price_per_night_cents * nights
    end
    platform = PlatformSetting.current
    rate = platform&.agency_commission_rate || 0.16
    self.commission_cents = (amount_cents * rate).round
  end

  def client_belongs_to_organization
    return if client.nil?

    errors.add(:client, "must belong to the booking organization") if client.organization_id != organization_id
  end

  def infer_room_type_from_room
    self.room_type ||= room&.room_type
  end

  # Discard a stale retreat_id that doesn't belong to the booking's hotel,
  # or one that has no pricing for the selected room type (i.e. a direct
  # lodging booking at a hotel that also hosts retreats). Prevents lodging
  # bookings from being priced as retreat bookings when the frontend sends
  # a leftover retreat_id from a previous browsing session.
  def clear_mismatched_retreat
    return unless retreat_id.present? && hotel_id.present?

    if retreat.hotel_id != hotel_id
      self.retreat_id = nil
    elsif room_type_id.present? && !experience_id.present?
      # No matching retreat pricing for this room type → direct lodging booking
      self.retreat_id = nil unless retreat.retreat_pricings.exists?(room_type_id: room_type_id)
    end
  end

  # Default guests to room type capacity when not explicitly set (i.e. still
  # at the DB default of 1). A couple room (capacity 2) should create a
  # booking for 2 guests automatically.
  def default_guests_from_room_type
    return unless room_type && guests == 1 && room_type.capacity > 1
    # Retreat pricing is per-guest; don't auto-bump guests to room capacity
    return if retreat_id.present? || experience_id.present?

    self.guests = room_type.capacity
  end

  def has_experience_or_hotel
    return if experience_id.present? || hotel_id.present?

    errors.add(:base, "must have either an experience or a hotel")
  end

  # When both are submitted they must name the same hotel — otherwise a
  # crafted hotel_id could surface the booking in another hotel's workspace.
  def hotel_matches_experience
    return if experience.nil? || hotel_id.nil?

    if experience.hotel_id != hotel_id
      errors.add(:hotel, "must match the experience's hotel")
    end
  end

  def room_type_belongs_to_experience_hotel
    return if room_type.nil?

    target_hotel_id = experience&.hotel_id || hotel_id
    return if target_hotel_id.nil?

    if room_type.hotel_id != target_hotel_id
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

  # Overbooking guard: only newly claimed inventory is checked — create, a
  # change of room type/dates, or reactivating a cancelled booking (its unit
  # may have been taken while it was cancelled). Historical bookings always
  # stay valid.
  def availability_check_needed?
    return false if status == "cancelled"
    return false unless room_type && starts_on && ends_on && ends_on > starts_on

    new_record? || will_save_change_to_room_type_id? ||
      will_save_change_to_starts_on? || will_save_change_to_ends_on? ||
      (will_save_change_to_status? && status_in_database == "cancelled")
  end

  def availability_calculator
    RoomTypeAvailability.new(
      room_type,
      from: starts_on,
      to: ends_on - 1, # checkout-exclusive
      exclude_booking_id: id
    )
  end

  def room_type_has_availability
    # Retreat bookings use the retreat's allocated_rooms, not the hotel's
    # physical room inventory. The creating agency has already committed
    # those rooms from their own inventory blocks.
    if retreat_id.present?
      validate_retreat_room_availability
      return
    end

    calc = availability_calculator
    # Room types without physical Room records don't track inventory; nothing
    # to enforce against.
    return unless calc.tracked?

    errors.add(:room_type, "has no availability for the selected dates") if calc.min_available < 1
  end

  def validate_retreat_room_availability
    pricing = retreat.retreat_pricings.find_by(room_type_id: room_type_id)
    return unless pricing&.allocated_rooms # no allocation = no constraint

    existing = Booking.active
                      .where(retreat_id: retreat_id, room_type_id: room_type_id)
                      .where.not(id: id)
                      .count
    if existing >= pricing.allocated_rooms
      errors.add(:room_type, "has no availability for the selected dates")
    end
  end

  # The validation above is a read-then-write race: two concurrent requests
  # can both see the last free unit before either insert commits. This hook
  # runs inside the save transaction holding a per-room-type advisory lock
  # (released at commit/rollback), so competing claims serialize and the
  # recheck sees every previously committed booking.
  INVENTORY_LOCK_NAMESPACE = 7201

  def reverify_availability_under_lock
    self.class.connection.execute(
      ActiveRecord::Base.sanitize_sql_array(
        ["SELECT pg_advisory_xact_lock(?, ?)", INVENTORY_LOCK_NAMESPACE, room_type_id]
      )
    )

    if retreat_id.present?
      validate_retreat_room_availability
      raise ActiveRecord::RecordInvalid, self if errors.any?
      return
    end

    calc = availability_calculator
    return unless calc.tracked?
    return if calc.min_available >= 1

    errors.add(:room_type, "has no availability for the selected dates")
    raise ActiveRecord::RecordInvalid, self
  end
end
