require "rails_helper"

RSpec.describe "Invitations API", type: :request do
  let!(:agency) { create(:organization, kind: "agency") }
  let!(:admin) { create(:user, :admin) }
  let!(:invitation) { create(:invitation, organization: agency, invited_by: admin) }

  describe "GET /api/v1/invitations/:token" do
    it "returns invitation details for a valid token" do
      get "/api/v1/invitations/#{invitation.token}"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["invitation"]["email"]).to eq(invitation.email)
      expect(body["invitation"]["organization"]["name"]).to eq(agency.name)
    end

    it "returns 404 for unknown token" do
      get "/api/v1/invitations/nonexistent-token"
      expect(response).to have_http_status(:not_found)
    end

    it "returns 410 for expired invitation" do
      invitation.update!(expires_at: 1.hour.ago)
      get "/api/v1/invitations/#{invitation.token}"
      expect(response).to have_http_status(:gone)
    end

    it "returns 409 for already accepted invitation" do
      invitation.update!(accepted_at: Time.current)
      get "/api/v1/invitations/#{invitation.token}"
      expect(response).to have_http_status(:conflict)
    end
  end

  describe "POST /api/v1/invitations/:token/accept" do
    let(:accept_params) do
      { user: { name: "New User", password: "humana1234", password_confirmation: "humana1234" } }
    end

    it "creates a user and returns a JWT" do
      expect {
        post "/api/v1/invitations/#{invitation.token}/accept",
             params: accept_params.to_json,
             headers: { "Content-Type" => "application/json" }
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_present
      expect(body["user"]["email"]).to eq(invitation.email)
      expect(body["user"]["status"]).to eq("active")
    end

    it "marks the invitation as accepted" do
      post "/api/v1/invitations/#{invitation.token}/accept",
           params: accept_params.to_json,
           headers: { "Content-Type" => "application/json" }

      expect(invitation.reload.accepted_at).to be_present
    end

    it "returns 422 for mismatched passwords" do
      params = { user: { name: "Test", password: "humana1234", password_confirmation: "wrong" } }
      post "/api/v1/invitations/#{invitation.token}/accept",
           params: params.to_json,
           headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 for short password" do
      params = { user: { name: "Test", password: "short", password_confirmation: "short" } }
      post "/api/v1/invitations/#{invitation.token}/accept",
           params: params.to_json,
           headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 409 for already accepted invitation" do
      invitation.update!(accepted_at: Time.current)

      post "/api/v1/invitations/#{invitation.token}/accept",
           params: accept_params.to_json,
           headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:conflict)
    end

    it "returns 410 for expired invitation" do
      invitation.update!(expires_at: 1.hour.ago)

      post "/api/v1/invitations/#{invitation.token}/accept",
           params: accept_params.to_json,
           headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:gone)
    end
  end
end
