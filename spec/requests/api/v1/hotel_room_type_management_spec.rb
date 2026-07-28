require "rails_helper"

RSpec.describe "Hotel Room Type Management API", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let!(:hotel) { create(:hotel, organization: hotel_org) }
  let(:owner) { create(:user, :owner, organization: hotel_org) }
  let!(:room_type) { create(:room_type, hotel: hotel, name: "Jungle Suite") }

  describe "PATCH /api/v1/hotel/room_types/:id" do
    it "updates status, amenities, and view type" do
      patch "/api/v1/hotel/room_types/#{room_type.id}",
            params: { room_type: { status: "draft", view_type: "garden",
                                   amenities: ["Air Conditioning", "Private Terrace"] } }.to_json,
            headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)["room_type"]
      expect(body["status"]).to eq("draft")
      expect(body["amenities_list"]).to eq(["Air Conditioning", "Private Terrace"])
      expect(body["view_type"]).to eq("garden")
    end

    it "rejects an unknown status" do
      patch "/api/v1/hotel/room_types/#{room_type.id}",
            params: { room_type: { status: "paused" } }.to_json,
            headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/hotel/room_types/:id" do
    it "includes images and rate tiers in the detail view" do
      room_type.room_images.create!(image_url: "https://img.test/a.jpg", position: 0, is_primary: true)
      room_type.room_rate_tiers.create!(min_rooms: 5, price_per_night_cents: 28_800)

      get "/api/v1/hotel/room_types/#{room_type.id}", headers: auth_headers(owner)

      body = JSON.parse(response.body)["room_type"]
      expect(body["images"].map { |i| i["image_url"] }).to eq(["https://img.test/a.jpg"])
      expect(body["rate_tiers"].first).to include("min_rooms" => 5, "price_per_night_cents" => 28_800)
    end
  end

  describe "POST /api/v1/hotel/room_types/:id/images/batch" do
    it "replaces the gallery and sets the primary image as thumbnail" do
      room_type.room_images.create!(image_url: "https://img.test/old.jpg", position: 0, is_primary: true)

      post "/api/v1/hotel/room_types/#{room_type.id}/images/batch",
           params: { images: [{ image_url: "https://img.test/a.jpg" },
                              { image_url: "https://img.test/b.jpg" }] }.to_json,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      images = room_type.reload.room_images.ordered
      expect(images.map(&:image_url)).to eq(["https://img.test/a.jpg", "https://img.test/b.jpg"])
      expect(images.first.is_primary).to be(true)
      expect(room_type.image_url).to eq("https://img.test/a.jpg")
    end

    it "rolls back entirely when any image is invalid" do
      room_type.update!(image_url: "https://img.test/old.jpg")
      room_type.room_images.create!(image_url: "https://img.test/old.jpg", position: 0, is_primary: true)

      post "/api/v1/hotel/room_types/#{room_type.id}/images/batch",
           params: { images: [{ image_url: "https://img.test/a.jpg" }, { image_url: "" }] }.to_json,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(room_type.reload.room_images.map(&:image_url)).to eq(["https://img.test/old.jpg"])
      expect(room_type.image_url).to eq("https://img.test/old.jpg")
    end
  end

  describe "room type lifecycle enforcement" do
    let(:agency) { create(:organization) }
    let(:experience) { create(:experience, hotel: hotel) }

    it "rejects new bookings for non-active room types" do
      room_type.update!(status: "inactive")
      booking = build(:booking, organization: agency, experience: experience, room_type: room_type)

      expect(booking).not_to be_valid
      expect(booking.errors[:room_type]).to include("is not open for sale")
    end

    it "keeps existing bookings valid when their room type is retired" do
      booking = create(:booking, organization: agency, experience: experience, room_type: room_type)
      room_type.update!(status: "inactive")

      booking.status = "completed"
      expect(booking).to be_valid
    end

    it "hides non-active room type pricing from discovery serialization but not from management" do
      retreat = create(:retreat, hotel: hotel, created_by_organization: hotel_org)
      active_type = create(:room_type, hotel: hotel, name: "Villa")
      retreat.retreat_pricings.create!(room_type: room_type, price_per_guest_cents: 100_000)
      retreat.retreat_pricings.create!(room_type: active_type, price_per_guest_cents: 200_000)
      room_type.update!(status: "draft")

      discovery = ApiSerializers.retreat(retreat)
      expect(discovery[:pricing].map { |p| p[:room_type][:name] }).to eq(["Villa"])

      management = ApiSerializers.retreat(retreat, all_pricing: true)
      expect(management[:pricing].length).to eq(2)

      get "/api/v1/hotel/retreats/#{retreat.id}", headers: auth_headers(owner)
      body = JSON.parse(response.body)["retreat"]
      expect(body["pricing"].length).to eq(2)
    end
  end

  describe "rate tiers CRUD" do
    it "creates, updates, and deletes tiers" do
      post "/api/v1/hotel/room_types/#{room_type.id}/rate_tiers",
           params: { rate_tier: { min_rooms: 5, price_per_night_cents: 28_800,
                                  starts_on: "2026-01-01", ends_on: "2026-12-31" } }.to_json,
           headers: auth_headers(owner)
      expect(response).to have_http_status(:created)
      tier_id = JSON.parse(response.body)["rate_tier"]["id"]

      patch "/api/v1/hotel/room_types/#{room_type.id}/rate_tiers/#{tier_id}",
            params: { rate_tier: { price_per_night_cents: 26_200 } }.to_json,
            headers: auth_headers(owner)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["rate_tier"]["price_per_night_cents"]).to eq(26_200)

      delete "/api/v1/hotel/room_types/#{room_type.id}/rate_tiers/#{tier_id}",
             headers: auth_headers(owner)
      expect(response).to have_http_status(:no_content)
      expect(room_type.room_rate_tiers.count).to eq(0)
    end

    it "rejects an inverted date range" do
      post "/api/v1/hotel/room_types/#{room_type.id}/rate_tiers",
           params: { rate_tier: { min_rooms: 5, price_per_night_cents: 28_800,
                                  starts_on: "2026-06-01", ends_on: "2026-01-01" } }.to_json,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 404 for another hotel's room type" do
      foreign = create(:room_type)
      post "/api/v1/hotel/room_types/#{foreign.id}/rate_tiers",
           params: { rate_tier: { min_rooms: 5, price_per_night_cents: 10_000 } }.to_json,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
    end
  end
end
