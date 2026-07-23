require "rails_helper"

RSpec.describe "Admin Countries API", type: :request do
  let!(:admin) { create(:user, :admin) }

  describe "GET /api/v1/admin/countries" do
    it "returns all countries" do
      create(:country, name: "Spain", code: "ES")
      create(:country, name: "Mexico", code: "MX", region: "LATAM")

      get "/api/v1/admin/countries", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["countries"].length).to eq(2)
    end

    it "filters by region" do
      create(:country, region: "Europe")
      create(:country, region: "LATAM")

      get "/api/v1/admin/countries", params: { region: "Europe" }, headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(body["countries"].length).to eq(1)
      expect(body["countries"].first["region"]).to eq("Europe")
    end

    it "returns 403 for non-admin" do
      agent = create(:user)
      get "/api/v1/admin/countries", headers: auth_headers(agent)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/admin/countries" do
    it "creates a new country" do
      params = { country: { name: "Portugal", code: "PT", region: "Europe", currency_code: "EUR" } }

      expect {
        post "/api/v1/admin/countries", params: params.to_json, headers: auth_headers(admin)
      }.to change(Country, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["country"]["code"]).to eq("PT")
    end
  end

  describe "PATCH /api/v1/admin/countries/:id" do
    it "updates a country" do
      country = create(:country, name: "Espana")

      patch "/api/v1/admin/countries/#{country.id}",
            params: { country: { name: "Spain" } }.to_json,
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(country.reload.name).to eq("Spain")
    end
  end

  describe "DELETE /api/v1/admin/countries/:id" do
    it "destroys a country" do
      country = create(:country)

      expect {
        delete "/api/v1/admin/countries/#{country.id}",
               params: { password: "humana1234", confirmation_text: country.name }.to_json,
               headers: auth_headers(admin)
      }.to change(Country, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "purges a country with hotels, rooms, and availability blocks" do
      country = create(:country, code: "ES")
      hotel_org = create(:organization, :hotel, country_code: "ES")
      hotel = create(:hotel, organization: hotel_org, country_code: "ES")
      room_type = create(:room_type, hotel: hotel, total_rooms: 2)
      create(:availability_block, room_type: room_type)
      agency = create(:organization, kind: "agency", country_code: "AR")
      experience = create(:experience, hotel: hotel, country_code: "ES")
      create(:booking, organization: agency, experience: experience,
                       room_type: room_type, room: room_type.rooms.first)

      expect {
        delete "/api/v1/admin/countries/#{country.id}",
               params: { password: "humana1234", confirmation_text: country.name }.to_json,
               headers: auth_headers(admin)
      }.to change(Country, :count).by(-1)

      expect(response).to have_http_status(:no_content)
      expect(Room.count).to eq(0)
      expect(AvailabilityBlock.count).to eq(0)
    end
  end
end
