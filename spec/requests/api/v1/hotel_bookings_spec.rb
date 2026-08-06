require "rails_helper"

# The hotel workspace must list bookings that arrive via one of the hotel's
# experiences AND bookings made directly against the hotel (e.g. published
# retreat bookings, which carry hotel_id but no experience).
RSpec.describe "Hotel bookings visibility", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let(:owner) { create(:user, :owner, organization: hotel_org) }
  let!(:hotel) { create(:hotel, organization: hotel_org) }
  let(:agency) { create(:organization, kind: "agency") }

  let!(:experience_booking) do
    experience = create(:experience, hotel: hotel)
    create(:booking, organization: agency, experience: experience,
                     starts_on: Date.current + 10, ends_on: Date.current + 14)
  end

  let!(:direct_booking) do
    create(:booking, organization: agency, experience: nil, hotel: hotel,
                     starts_on: Date.current + 20, ends_on: Date.current + 24)
  end

  let!(:other_hotel_booking) do
    other_org = create(:organization, :hotel)
    other_hotel = create(:hotel, organization: other_org)
    create(:booking, organization: agency, experience: nil, hotel: other_hotel,
                     starts_on: Date.current + 30, ends_on: Date.current + 34)
  end

  it "lists experience-based and direct bookings, not other hotels'" do
    get "/api/v1/hotel/bookings", headers: auth_headers(owner)

    expect(response).to have_http_status(:ok)
    ids = JSON.parse(response.body)["bookings"].map { |b| b["id"] }
    expect(ids).to include(experience_booking.id, direct_booking.id)
    expect(ids).not_to include(other_hotel_booking.id)
  end

  it "ignores hotel_id when the booking has an experience (other hotel)" do
    other_org = create(:organization, :hotel)
    other_hotel = create(:hotel, organization: other_org)
    other_experience = create(:experience, hotel: other_hotel)
    # Bypass validations to simulate pre-existing mismatched data
    crafted = build(:booking, organization: agency, experience: other_experience,
                              starts_on: Date.current + 5, ends_on: Date.current + 8)
    crafted.hotel_id = hotel.id
    crafted.reference = "HMN-CRAFT1"
    crafted.save!(validate: false)

    get "/api/v1/hotel/bookings", headers: auth_headers(owner)

    ids = JSON.parse(response.body)["bookings"].map { |b| b["id"] }
    expect(ids).not_to include(crafted.id)
  end

  it "rejects bookings whose hotel_id mismatches the experience's hotel" do
    other_org = create(:organization, :hotel)
    other_hotel = create(:hotel, organization: other_org)
    experience = create(:experience, hotel: other_hotel)

    booking = build(:booking, organization: agency, experience: experience, hotel: hotel)

    expect(booking).not_to be_valid
    expect(booking.errors[:hotel]).to include("must match the experience's hotel")
  end
end
