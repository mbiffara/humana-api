class Client < ApplicationRecord
  belongs_to :organization
  has_many :bookings, dependent: :nullify

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end
