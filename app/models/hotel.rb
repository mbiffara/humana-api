class Hotel < ApplicationRecord
  belongs_to :organization
  has_many :experiences, dependent: :destroy

  validates :name, presence: true

  scope :certified, -> { where(certified: true) }
end
