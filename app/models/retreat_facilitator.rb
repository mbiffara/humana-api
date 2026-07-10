# Expert practitioner leading or assisting in a retreat program.
# Displayed on the retreat detail page with avatar, specialty, and bio.
class RetreatFacilitator < ApplicationRecord
  ROLES = %w[lead assistant guest].freeze

  belongs_to :retreat

  validates :name, presence: true
  validates :role, inclusion: { in: ROLES }

  scope :leads, -> { where(role: "lead") }
  scope :ordered, -> { order(position: :asc) }
end
