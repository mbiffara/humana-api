class Hotel < ApplicationRecord
  belongs_to :organization
  has_many :experiences, dependent: :destroy

  validates :name, presence: true

  scope :certified, -> { where(certified: true) }
  scope :in_country, ->(code) { code.present? ? where(country_code: code.upcase) : all }
  scope :search, ->(q) {
    next all if q.blank?

    term = "%#{sanitize_sql_like(q)}%"
    where("name ILIKE :t OR city ILIKE :t OR country ILIKE :t", t: term)
  }
end
