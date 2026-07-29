require "rails_helper"

RSpec.describe "Public hotel availability API", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let!(:hotel) { create(:hotel, organization: hotel_org) }
  let!(:room_type) { create(:room_type, hotel: hotel, name: "Suite") }
  let(:agency) { create(:organization) }
  let(:experience) { create(:experience, hotel: hotel) }

  before do
    create(:room, room_type: room_type, number: "Suite 1")
    create(:room, room_type: room_type, number: "Suite 2")
  end

  it "returns per-day availability without authentication" do
    create(:booking, organization: agency, experience: experience, room_type: room_type,
                     guests: 2, starts_on: Date.current, ends_on: Date.current + 2)
    create(:availability_block, hotel: hotel, room_type: room_type, units: 1,
                                starts_on: Date.current + 1, ends_on: Date.current + 1)

    get "/api/v1/public/hotels/#{hotel.id}/availability?from=#{Date.current}&to=#{Date.current + 2}"

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    days = body["room_types"].first["days"]
    expect(days.map { |d| d["available"] }).to eq([1, 0, 2]) # booked / booked+blocked / free
    expect(days.first["total"]).to eq(2)
  end

  it "only lists room types that are open for sale" do
    create(:room_type, hotel: hotel, name: "Retired", status: "inactive")

    get "/api/v1/public/hotels/#{hotel.id}/availability"

    names = JSON.parse(response.body)["room_types"].map { |rt| rt["room_type"]["name"] }
    expect(names).to eq(["Suite"])
  end

  it "rejects an inverted date range" do
    get "/api/v1/public/hotels/#{hotel.id}/availability?from=#{Date.current}&to=#{Date.current - 1}"
    expect(response).to have_http_status(:bad_request)
  end
end
