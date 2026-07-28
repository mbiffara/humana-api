require "rails_helper"

# Role guard + tenant scoping for the hotel workspace (JON-25).
RSpec.describe "Hotel workspace access", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let(:owner) { create(:user, :owner, organization: hotel_org) }

  context "when the organization has a hotel record" do
    let!(:hotel) { create(:hotel, organization: hotel_org) }

    it "allows hotel endpoints" do
      get "/api/v1/hotel/room_types", headers: auth_headers(owner)
      expect(response).to have_http_status(:ok)
    end

    it "rejects users from non-hotel organizations" do
      agency_user = create(:user)
      get "/api/v1/hotel/room_types", headers: auth_headers(agency_user)

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["error"]).to eq("Hotel access required")
    end

    it "rejects platform admin users" do
      admin = create(:user, :admin)
      get "/api/v1/hotel/room_types", headers: auth_headers(admin)

      expect(response).to have_http_status(:forbidden)
    end

    it "rejects unauthenticated requests" do
      get "/api/v1/hotel/room_types"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when the organization has no hotel record yet (onboarding not finished)" do
    it "returns a clean 403 instead of crashing" do
      get "/api/v1/hotel/room_types", headers: auth_headers(owner)

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["error"]).to eq("Hotel profile is not set up yet")
    end

    it "still allows the profile endpoint, which creates the record" do
      get "/api/v1/hotel/profile", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["hotel"]).to be_nil
    end
  end
end
