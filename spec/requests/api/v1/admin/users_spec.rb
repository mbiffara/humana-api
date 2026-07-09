require "rails_helper"

RSpec.describe "Admin Users API", type: :request do
  let!(:admin) { create(:user, :admin) }
  let!(:agency) { create(:organization, kind: "agency", name: "Test Agency") }
  let!(:agent) { create(:user, name: "Agent Smith", organization: agency) }

  describe "GET /api/v1/admin/users" do
    it "returns all non-admin users" do
      get "/api/v1/admin/users", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      emails = body["users"].map { |u| u["email"] }
      expect(emails).to include(agent.email)
      expect(emails).not_to include(admin.email)
    end

    it "filters by status" do
      pending_user = create(:user, :pending, organization: agency, name: "Pending User")

      get "/api/v1/admin/users", params: { status: "pending" }, headers: auth_headers(admin)

      body = JSON.parse(response.body)
      statuses = body["users"].map { |u| u["status"] }
      expect(statuses).to all(eq("pending"))
    end

    it "searches by name" do
      get "/api/v1/admin/users", params: { q: "Smith" }, headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(body["users"].length).to eq(1)
      expect(body["users"].first["name"]).to eq("Agent Smith")
    end
  end

  describe "POST /api/v1/admin/users/invite" do
    it "creates an invitation and returns magic link" do
      params = { invitation: { email: "new@agency.com", role: "member", organization_id: agency.id } }

      expect {
        post "/api/v1/admin/users/invite", params: params.to_json, headers: auth_headers(admin)
      }.to change(Invitation, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["invitation"]["email"]).to eq("new@agency.com")
      expect(body["invitation"]["magic_link"]).to include("accept-invite?token=")
    end

    it "returns 403 for non-admin user" do
      params = { invitation: { email: "hack@test.com", role: "member", organization_id: agency.id } }
      post "/api/v1/admin/users/invite", params: params.to_json, headers: auth_headers(agent)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/admin/users/:id/approve" do
    it "sets user status to active" do
      pending_user = create(:user, :pending, organization: agency)

      post "/api/v1/admin/users/#{pending_user.id}/approve", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(pending_user.reload.status).to eq("active")
    end
  end

  describe "POST /api/v1/admin/users/:id/reject" do
    it "sets user status to rejected" do
      pending_user = create(:user, :pending, organization: agency)

      post "/api/v1/admin/users/#{pending_user.id}/reject",
           params: { reason: "Not verified" }.to_json,
           headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(pending_user.reload.status).to eq("rejected")
    end
  end

  describe "POST /api/v1/admin/users/:id/suspend" do
    it "sets user status to suspended" do
      post "/api/v1/admin/users/#{agent.id}/suspend", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(agent.reload.status).to eq("suspended")
    end
  end

  describe "POST /api/v1/admin/users/:id/reactivate" do
    it "sets suspended user back to active" do
      agent.update!(status: "suspended")

      post "/api/v1/admin/users/#{agent.id}/reactivate", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(agent.reload.status).to eq("active")
    end
  end
end
