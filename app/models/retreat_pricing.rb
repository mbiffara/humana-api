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

  def price_per_guest
    price_per_guest_cents / 100.0
  end
end
