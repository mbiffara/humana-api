# Gallery photo for a common space. The first image of the gallery is the
# primary one and doubles as the space thumbnail.
class CommonSpaceImage < ApplicationRecord
  belongs_to :common_space

  validates :image_url, presence: true

  scope :ordered, -> { order(position: :asc, id: :asc) }
end
