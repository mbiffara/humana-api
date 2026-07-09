require "rails_helper"

RSpec.describe "Admin Retreats API", type: :request do
  let!(:admin) { create(:user, :admin) }
  let!(:hotel) { create(:hotel) }
  let!(:retreat) { create(:retreat, hotel: hotel, created_by_organization: hotel.organization, status: "pending_review") }

  describe "GET /api/v1/admin/retreats" do
    it "returns all retreats" do
      get "/api/v1/admin/retreats", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["retreats"].length).to eq(1)
      expect(body["meta"]).to include("page", "per_page", "total", "total_pages")
    end

    it "filters by status" do
      create(:retreat, :active, hotel: hotel, created_by_organization: hotel.organization)

      get "/api/v1/admin/retreats", params: { status: "active" }, headers: auth_headers(admin)

      body = JSON.parse(response.body)
      body["retreats"].each do |r|
        expect(r["status"]).to eq("active")
      end
    end
  end

  describe "POST /api/v1/admin/retreats/:id/approve" do
    it "approves a pending retreat" do
      post "/api/v1/admin/retreats/#{retreat.id}/approve", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(retreat.reload.status).to eq("active")
      expect(retreat.published_at).to be_present
    end
  end

  describe "POST /api/v1/admin/retreats/:id/close" do
    it "closes a retreat" do
      post "/api/v1/admin/retreats/#{retreat.id}/close", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(retreat.reload.status).to eq("closed")
    end
  end
end
