require "rails_helper"

RSpec.describe "Hotel Rooms API", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let!(:hotel) { create(:hotel, organization: hotel_org) }
  let(:owner) { create(:user, :owner, organization: hotel_org) }
  let(:room_type) { create(:room_type, hotel: hotel, name: "Suite") }

  describe "GET /api/v1/hotel/rooms" do
    before do
      create(:room, room_type: room_type, number: "Suite 1")
      create(:room, room_type: room_type, number: "Suite 2", status: "maintenance")
    end

    it "lists the hotel's rooms" do
      get "/api/v1/hotel/rooms", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["rooms"].map { |r| r["number"] }).to contain_exactly("Suite 1", "Suite 2")
    end

    it "filters by status" do
      get "/api/v1/hotel/rooms?status=maintenance", headers: auth_headers(owner)

      body = JSON.parse(response.body)
      expect(body["rooms"].map { |r| r["number"] }).to eq(["Suite 2"])
    end

    it "is forbidden for agency users" do
      agency_user = create(:user)
      get "/api/v1/hotel/rooms", headers: auth_headers(agency_user)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/hotel/rooms" do
    it "creates a room and refreshes the room type's total_rooms" do
      post "/api/v1/hotel/rooms",
           params: { room: { room_type_id: room_type.id, number: "Suite 10" } }.to_json,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["room"]["number"]).to eq("Suite 10")
      expect(body["room"]["auto_generated"]).to eq(false)
      expect(room_type.reload.total_rooms).to eq(1)
    end

    it "rejects a room type belonging to another hotel" do
      foreign_type = create(:room_type)
      post "/api/v1/hotel/rooms",
           params: { room: { room_type_id: foreign_type.id, number: "Intruder 1" } }.to_json,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects duplicate numbers" do
      create(:room, room_type: room_type, number: "Suite 1")
      post "/api/v1/hotel/rooms",
           params: { room: { room_type_id: room_type.id, number: "suite 1" } }.to_json,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/hotel/rooms/:id" do
    it "renames a room and updates its status" do
      room = create(:room, room_type: room_type, number: "Suite 1")
      patch "/api/v1/hotel/rooms/#{room.id}",
            params: { room: { number: "Villa Azul", status: "maintenance" } }.to_json,
            headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(room.reload.number).to eq("Villa Azul")
      expect(room.status).to eq("maintenance")
    end

    it "returns 404 for another hotel's room" do
      foreign_room = create(:room)
      patch "/api/v1/hotel/rooms/#{foreign_room.id}",
            params: { room: { number: "Hijacked" } }.to_json,
            headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/hotel/rooms/:id" do
    it "deletes a room and refreshes total_rooms" do
      room_type.update!(total_rooms: 2)
      room = room_type.rooms.first

      delete "/api/v1/hotel/rooms/#{room.id}", headers: auth_headers(owner)

      expect(response).to have_http_status(:no_content)
      expect(room_type.reload.total_rooms).to eq(1)
    end
  end
end
