class Organization < ApplicationRecord
  KINDS = %w[hotel agency admin].freeze
  STATUSES = %w[pending verified suspended].freeze

  has_many :users, dependent: :destroy
  has_many :hotels, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :bookings, dependent: :destroy

  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }

  scope :hotels_kind, -> { where(kind: "hotel") }
  scope :agencies, -> { where(kind: "agency") }
  scope :verified, -> { where(status: "verified") }

  def agency?
    kind == "agency"
  end

  def hotel?
    kind == "hotel"
  end

  def admin?
    kind == "admin"
  end
end
