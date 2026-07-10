# Gallery image for a specific room type. Shown in the room inventory section
# of hotel onboarding (step 2) and in room detail views. One image can be
# marked as primary for use as the room type thumbnail.
class RoomImage < ApplicationRecord
  belongs_to :room_type

  validates :image_url, presence: true

  scope :ordered, -> { order(position: :asc) }
  scope :primary, -> { where(is_primary: true) }
end
