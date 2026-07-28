require "rails_helper"

RSpec.describe "Hotel Dashboard API", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let!(:hotel) { create(:hotel, organization: hotel_org) }
  let(:owner) { create(:user, :owner, organization: hotel_org) }
  let(:agency) { create(:organization) }
  let!(:room_type) { create(:room_type, hotel: hotel, name: "Suite") }
  let!(:experience) { create(:experience, hotel: hotel, price_cents: 100_000) }

  def create_booking(**attrs)
    create(:booking, organization: agency, experience: experience, room_type: room_type, **attrs)
  end

  describe "GET /api/v1/hotel/dashboard" do
    it "returns the aggregated dashboard payload" do
      create(:room, room_type: room_type, number: "Suite 1")
      create(:room, room_type: room_type, number: "Suite 2")

      client = agency.clients.create!(name: "Maria Lopez")
      create_booking(client: client, guests: 2, starts_on: Date.current, ends_on: Date.current + 7)
      create_booking(guests: 3, starts_on: Date.current + 3, ends_on: Date.current + 8)
      # Outside the 7-day upcoming window
      create_booking(guests: 4, starts_on: Date.current + 20, ends_on: Date.current + 25)
      # Cancelled bookings never count
      create_booking(guests: 9, starts_on: Date.current + 1, ends_on: Date.current + 2, status: "cancelled")

      create(:retreat, :active, hotel: hotel, created_by_organization: hotel_org,
                                name: "Zen Interior", starts_on: Date.current - 2, ends_on: Date.current + 3)
      create(:retreat, :upcoming, hotel: hotel, created_by_organization: hotel_org,
                                  name: "Spring Detox", starts_on: Date.current + 10, ends_on: Date.current + 15)

      get "/api/v1/hotel/dashboard", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      dashboard = JSON.parse(response.body)["dashboard"]

      expect(dashboard["hotel"]["name"]).to eq(hotel.name)
      expect(dashboard["hotel"]["rooms_total"]).to eq(2)

      expect(dashboard["occupancy"]["rate"]).to be > 0
      expect(dashboard["revenue"]["current_cents"]).to eq(500_000) # (2 + 3) guests * $1000
      expect(dashboard["upcoming"]).to eq({ "guests" => 5, "check_ins_today" => 1 })

      check_ins = dashboard["next_check_ins"]
      expect(check_ins.length).to eq(3)
      expect(check_ins.first).to include(
        "guest_name" => "Maria Lopez",
        "room_type" => "Suite",
        "days_until" => 0,
        "nights" => 7,
        "agency" => agency.name,
      )

      expect(dashboard["retreats"]["in_progress"]).to eq(1)
      expect(dashboard["retreats"]["upcoming"]).to eq(1)
      expect(dashboard["retreats"]["items"].map { |i| i["state"] }).to eq(%w[in_progress upcoming])
    end

    it "returns zeroed stats for a hotel with no activity" do
      get "/api/v1/hotel/dashboard", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      dashboard = JSON.parse(response.body)["dashboard"]
      expect(dashboard["occupancy"]["rate"]).to eq(0)
      expect(dashboard["revenue"]["current_cents"]).to eq(0)
      expect(dashboard["upcoming"]).to eq({ "guests" => 0, "check_ins_today" => 0 })
      expect(dashboard["next_check_ins"]).to eq([])
      expect(dashboard["retreats"]["items"]).to eq([])
    end

    it "is forbidden for agency users" do
      agency_user = create(:user)
      get "/api/v1/hotel/dashboard", headers: auth_headers(agency_user)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
