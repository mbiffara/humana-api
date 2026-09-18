require "rails_helper"

RSpec.describe "Admin Organizations API", type: :request do
  let!(:admin) { create(:user, :admin) }
  let!(:agency) { create(:organization, kind: "agency", name: "Test Agency") }
  let!(:hotel_org) { create(:organization, :hotel, name: "Test Hotel") }
  let!(:office) { create(:organization, :office, name: "HUMANA LATAM") }

  describe "GET /api/v1/admin/organizations" do
    it "returns all non-admin organizations" do
      get "/api/v1/admin/organizations", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["organizations"].length).to eq(3)
      kinds = body["organizations"].map { |o| o["kind"] }
      expect(kinds).not_to include("admin")
    end

    it "filters by kind" do
      get "/api/v1/admin/organizations", params: { kind: "office" }, headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(body["organizations"].length).to eq(1)
      expect(body["organizations"].first["kind"]).to eq("office")
    end

    it "filters by search query" do
      get "/api/v1/admin/organizations", params: { q: "LATAM" }, headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(body["organizations"].length).to eq(1)
      expect(body["organizations"].first["name"]).to eq("HUMANA LATAM")
    end

    it "returns 403 for non-admin user" do
      agent = create(:user, organization: agency)
      get "/api/v1/admin/organizations", headers: auth_headers(agent)
      expect(response).to have_http_status(:forbidden)
    end

    it "includes pagination metadata" do
      get "/api/v1/admin/organizations", headers: auth_headers(admin)

      body = JSON.parse(response.body)
      expect(body["meta"]).to include("page", "per_page", "total", "total_pages")
    end
  end

  # The review screen reads the verification block (LOG-157) straight off the
  # organization, so the admin serializer has to carry it.
  describe "GET /api/v1/admin/organizations/:id" do
    before do
      hotel_org.update!(
        legal_name: "Shanti Wellness S.L.",
        business_name: "Shanti Retreat Ibiza",
        tax_id: "B12345678",
        primary_contact: "Marta Ferrer",
        primary_contact_role: "Directora General",
        commercial_registration: "RM Ibiza, tomo 1234, folio 56",
        phone: "+34 971 123 456",
        website: "https://shantiretreat.com",
        social_links: { "instagram" => "https://instagram.com/shanti" },
        ownership_document_url: "https://cdn.humana.global/documents/deed.pdf",
        authorization_declared_at: Time.current
      )
    end

    it "returns the verification block" do
      get "/api/v1/admin/organizations/#{hotel_org.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      org = response.parsed_body["organization"]
      expect(org["legal_name"]).to eq("Shanti Wellness S.L.")
      expect(org["business_name"]).to eq("Shanti Retreat Ibiza")
      expect(org["tax_id"]).to eq("B12345678")
      expect(org["primary_contact"]).to eq("Marta Ferrer")
      expect(org["primary_contact_role"]).to eq("Directora General")
      expect(org["commercial_registration"]).to eq("RM Ibiza, tomo 1234, folio 56")
      expect(org["phone"]).to eq("+34 971 123 456")
      expect(org["website"]).to eq("https://shantiretreat.com")
      expect(org["social_links"]).to eq("instagram" => "https://instagram.com/shanti")
      expect(org["ownership_document_url"]).to eq("https://cdn.humana.global/documents/deed.pdf")
      expect(org["authorization_declared_at"]).to be_present
    end

    it "carries the same block in the list" do
      get "/api/v1/admin/organizations", headers: auth_headers(admin)

      org = response.parsed_body["organizations"].find { |o| o["id"] == hotel_org.id }
      expect(org["legal_name"]).to eq("Shanti Wellness S.L.")
      expect(org["social_links"]).to eq("instagram" => "https://instagram.com/shanti")
    end
  end

  describe "POST /api/v1/admin/organizations" do
    it "creates a new organization" do
      params = { organization: { name: "New Office", kind: "office", status: "verified",
                                 city: "Lima", country: "Peru", country_code: "PE" } }

      expect {
        post "/api/v1/admin/organizations", params: params.to_json, headers: auth_headers(admin)
      }.to change(Organization, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["organization"]["name"]).to eq("New Office")
    end
  end

  describe "PATCH /api/v1/admin/organizations/:id" do
    it "updates an organization" do
      patch "/api/v1/admin/organizations/#{agency.id}",
            params: { organization: { name: "Updated Agency" } }.to_json,
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(agency.reload.name).to eq("Updated Agency")
    end

    it "toggles sponsored access for a hotel organization" do
      patch "/api/v1/admin/organizations/#{hotel_org.id}",
            params: { organization: { sponsored: true } }.to_json,
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(hotel_org.reload.sponsored).to be(true)
      body = JSON.parse(response.body)
      expect(body["organization"]["sponsored"]).to be(true)
    end
  end

  describe "DELETE /api/v1/admin/organizations/:id" do
    it "destroys an organization" do
      expect {
        delete "/api/v1/admin/organizations/#{office.id}", headers: auth_headers(admin)
      }.to change(Organization, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
