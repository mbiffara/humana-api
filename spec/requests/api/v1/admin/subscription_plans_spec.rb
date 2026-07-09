require "rails_helper"

RSpec.describe "Admin Subscription Plans API", type: :request do
  let!(:admin) { create(:user, :admin) }

  describe "GET /api/v1/admin/subscription_plans" do
    it "returns all plans" do
      create(:subscription_plan, name: "Starter", position: 0)
      create(:subscription_plan, name: "Professional", position: 1)

      get "/api/v1/admin/subscription_plans", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["subscription_plans"].length).to eq(2)
    end

    it "filters by active" do
      create(:subscription_plan, active: true)
      create(:subscription_plan, active: false)

      get "/api/v1/admin/subscription_plans", params: { active: "true" }, headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(body["subscription_plans"].length).to eq(1)
    end
  end

  describe "POST /api/v1/admin/subscription_plans" do
    it "creates a new plan" do
      params = { subscription_plan: {
        name: "Enterprise", price_cents: 29900, commission_rate: 0.12,
        billing_interval: "monthly", target_audience: "agency"
      } }

      expect {
        post "/api/v1/admin/subscription_plans", params: params.to_json, headers: auth_headers(admin)
      }.to change(SubscriptionPlan, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /api/v1/admin/subscription_plans/:id" do
    it "updates a plan" do
      plan = create(:subscription_plan, name: "Basic")

      patch "/api/v1/admin/subscription_plans/#{plan.id}",
            params: { subscription_plan: { name: "Starter" } }.to_json,
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(plan.reload.name).to eq("Starter")
    end
  end
end
