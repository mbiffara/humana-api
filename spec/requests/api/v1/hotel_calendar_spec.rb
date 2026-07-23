require "rails_helper"

RSpec.describe "Hotel Calendar API", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let(:hotel) { create(:hotel, organization: hotel_org) }
  let(:owner) { create(:user, :owner, organization: hotel_org) }
  let(:agency) { create(:organization, kind: "agency") }
  let(:experience) { create(:experience, hotel: hotel, starts_on: nil, ends_on: nil) }
  let!(:suite) { create(:room_type, hotel: hotel, name: "Suite", total_rooms: 2) }

  def get_calendar(from:, to:)
    get "/api/v1/hotel/calendar?from=#{from}&to=#{to}", headers: auth_headers(owner)
    expect(response).to have_http_status(:ok)
    JSON.parse(response.body)
  end

  it "returns per-day availability for each room type" do
    create(:booking, organization: agency, experience: experience, room_type: suite,
                     starts_on: Date.new(2026, 8, 10), ends_on: Date.new(2026, 8, 12))

    body = get_calendar(from: "2026-08-09", to: "2026-08-12")
    entry = body["room_types"].find { |rt| rt["room_type"]["id"] == suite.id }

    expect(entry["rooms_total"]).to eq(2)
    expect(entry["rooms_operational"]).to eq(2)

    days = entry["days"].index_by { |d| d["date"] }
    expect(days["2026-08-09"]).to include("booked" => 0, "available" => 2)
    expect(days["2026-08-10"]).to include("booked" => 1, "available" => 1)
    expect(days["2026-08-11"]).to include("booked" => 1, "available" => 1)
    # Checkout day: the room is free again.
    expect(days["2026-08-12"]).to include("booked" => 0, "available" => 2)
  end

  it "excludes cancelled bookings and rooms under maintenance" do
    suite.rooms.first.update!(status: "maintenance")
    create(:booking, organization: agency, experience: experience, room_type: suite,
                     status: "cancelled",
                     starts_on: Date.new(2026, 8, 10), ends_on: Date.new(2026, 8, 12))

    body = get_calendar(from: "2026-08-10", to: "2026-08-10")
    entry = body["room_types"].find { |rt| rt["room_type"]["id"] == suite.id }

    expect(entry["rooms_operational"]).to eq(1)
    expect(entry["days"].first).to include("booked" => 0, "available" => 1)
  end

  it "counts bookings without a room type as unassigned" do
    create(:booking, organization: agency, experience: experience,
                     starts_on: Date.new(2026, 8, 10), ends_on: Date.new(2026, 8, 12))

    body = get_calendar(from: "2026-08-10", to: "2026-08-11")
    counts = body["unassigned_bookings"].index_by { |d| d["date"] }

    expect(counts["2026-08-10"]["count"]).to eq(1)
    expect(counts["2026-08-11"]["count"]).to eq(1)
    entry = body["room_types"].find { |rt| rt["room_type"]["id"] == suite.id }
    expect(entry["days"].first).to include("booked" => 0)
  end

  it "rejects a range where to precedes from" do
    get "/api/v1/hotel/calendar?from=2026-08-10&to=2026-08-01", headers: auth_headers(owner)
    expect(response).to have_http_status(:bad_request)
  end

  it "caps the range at 92 days" do
    body = get_calendar(from: "2026-01-01", to: "2026-12-31")
    expect(Date.parse(body["to"])).to eq(Date.new(2026, 1, 1) + 91)
  end

  it "is forbidden for agency users" do
    agency_user = create(:user, organization: agency)
    get "/api/v1/hotel/calendar", headers: auth_headers(agency_user)
    expect(response).to have_http_status(:forbidden)
  end
end
