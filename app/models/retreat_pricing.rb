# Per-room-type pricing for a retreat. Different room categories within the
# same retreat have different per-guest rates. Referenced during the booking
# flow's accommodation selection step.
class RetreatPricing < ApplicationRecord
  belongs_to :retreat
  belongs_to :room_type

  validates :price_per_guest_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :room_type_id, uniqueness: { scope: :retreat_id,
    message: "pricing already exists for this room type in this retreat" }

  scope :ordered, -> { joins(:room_type).order("room_types.position ASC") }

  after_commit :refresh_retreat_min_price

  def price_per_guest
    price_per_guest_cents / 100.0
  end

  private

  # Retreat#min_price_cents is cached at save time, so pricing changes must
  # push the recomputed value back onto the parent.
  def refresh_retreat_min_price
    return if destroyed_by_association

    retreat.update_column(:min_price_cents, retreat.retreat_pricings.minimum(:price_per_guest_cents) || 0)
  end
end
