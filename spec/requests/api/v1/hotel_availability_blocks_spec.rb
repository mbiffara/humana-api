require "rails_helper"

RSpec.describe "Hotel Availability Blocks API", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let!(:hotel) { create(:hotel, organization: hotel_org) }
  let(:owner) { create(:user, :owner, organization: hotel_org) }
  let(:room_type) { create(:room_type, hotel: hotel, name: "Suite", total_rooms: 3) }

  describe "GET /api/v1/hotel/availability_blocks" do
    it "lists the hotel's blocks" do
      create(:availability_block, room_type: room_type, units: 2)
      get "/api/v1/hotel/availability_blocks", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["availability_blocks"].size).to eq(1)
      expect(body["availability_blocks"].first["units"]).to eq(2)
    end

    it "is forbidden for agency users" do
      get "/api/v1/hotel/availability_blocks", headers: auth_headers(create(:user))
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/hotel/availability_blocks" do
    it "creates a block" do
      post "/api/v1/hotel/availability_blocks",
           params: { availability_block: { room_type_id: room_type.id, starts_on: "2026-11-01",
                                           ends_on: "2026-11-30", units: 1, reason: "Renovation" } }.to_json,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["availability_block"]["reason"]).to eq("Renovation")
    end

    it "rejects an inverted date range" do
      post "/api/v1/hotel/availability_blocks",
           params: { availability_block: { room_type_id: room_type.id, starts_on: "2026-11-30",
                                           ends_on: "2026-11-01" } }.to_json,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a room type from another hotel" do
      foreign_type = create(:room_type)
      post "/api/v1/hotel/availability_blocks",
           params: { availability_block: { room_type_id: foreign_type.id, starts_on: "2026-11-01",
                                           ends_on: "2026-11-30" } }.to_json,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/hotel/availability_blocks/:id" do
    it "removes a block" do
      block = create(:availability_block, room_type: room_type)
      delete "/api/v1/hotel/availability_blocks/#{block.id}", headers: auth_headers(owner)

      expect(response).to have_http_status(:no_content)
      expect(AvailabilityBlock.exists?(block.id)).to be(false)
    end

    it "returns 404 for another hotel's block" do
      foreign = create(:availability_block)
      delete "/api/v1/hotel/availability_blocks/#{foreign.id}", headers: auth_headers(owner)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "calendar integration" do
    it "subtracts blocked units from availability" do
      room_type.update!(total_rooms: 3)
      create(:availability_block, room_type: room_type,
                                  starts_on: Date.new(2026, 11, 10), ends_on: Date.new(2026, 11, 11), units: 2)
      create(:availability_block, room_type: room_type,
                                  starts_on: Date.new(2026, 11, 11), ends_on: Date.new(2026, 11, 12))

      get "/api/v1/hotel/calendar?from=2026-11-09&to=2026-11-13", headers: auth_headers(owner)
      expect(response).to have_http_status(:ok)
      entry = JSON.parse(response.body)["room_types"].find { |rt| rt["room_type"]["id"] == room_type.id }
      days = entry["days"].index_by { |d| d["date"] }

      expect(days["2026-11-09"]).to include("blocked" => 0, "available" => 3)
      expect(days["2026-11-10"]).to include("blocked" => 2, "available" => 1)
      # Overlapping blocks: 2 units + whole-type block, capped at operational.
      expect(days["2026-11-11"]).to include("blocked" => 3, "available" => 0)
      # units: nil closes the whole type.
      expect(days["2026-11-12"]).to include("blocked" => 3, "available" => 0)
      expect(days["2026-11-13"]).to include("blocked" => 0, "available" => 3)
    end
  end
end
