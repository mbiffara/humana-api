require "rails_helper"

RSpec.describe "Hotel Retreats API", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let!(:hotel) { create(:hotel, organization: hotel_org) }
  let(:owner) { create(:user, :owner, organization: hotel_org) }

  def create_retreat(**attrs)
    create(:retreat, hotel: hotel, created_by_organization: hotel_org, **attrs)
  end

  describe "GET /api/v1/hotel/retreats" do
    before do
      create_retreat(name: "Wellness Immersion", status: "active", published_at: Time.current)
      create_retreat(name: "Spring Detox")
    end

    it "lists the hotel's retreats" do
      get "/api/v1/hotel/retreats", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["retreats"].map { |r| r["name"] }).to contain_exactly("Wellness Immersion", "Spring Detox")
    end

    it "filters by status" do
      get "/api/v1/hotel/retreats?status=draft", headers: auth_headers(owner)

      body = JSON.parse(response.body)
      expect(body["retreats"].map { |r| r["name"] }).to eq(["Spring Detox"])
    end

    it "is forbidden for agency users" do
      agency_user = create(:user)
      get "/api/v1/hotel/retreats", headers: auth_headers(agency_user)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/hotel/retreats" do
    it "creates a draft retreat owned by the hotel" do
      post "/api/v1/hotel/retreats",
           params: { retreat: { name: "El Arte del Silencio", retreat_type: "wellness",
                                duration_nights: 6, capacity: 14, language: "es" } }.to_json,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["retreat"]["status"]).to eq("draft")
      expect(body["retreat"]["created_by_type"]).to eq("hotel")
      expect(hotel.retreats.count).to eq(1)
    end

    it "rejects an invalid retreat type" do
      post "/api/v1/hotel/retreats",
           params: { retreat: { name: "Bad Type", retreat_type: "party", duration_nights: 3 } }.to_json,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/hotel/retreats/:id/publish" do
    it "publishes a draft retreat" do
      retreat = create_retreat

      post "/api/v1/hotel/retreats/#{retreat.id}/publish", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(retreat.reload.status).to eq("active")
      expect(retreat.published_at).to be_present
    end

    it "rejects publishing an already active retreat" do
      retreat = create_retreat(status: "active", published_at: Time.current)

      post "/api/v1/hotel/retreats/#{retreat.id}/publish", headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 404 for another hotel's retreat" do
      foreign = create(:retreat)

      post "/api/v1/hotel/retreats/#{foreign.id}/publish", headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/hotel/retreats/:id" do
    it "deletes a draft retreat" do
      retreat = create_retreat

      delete "/api/v1/hotel/retreats/#{retreat.id}", headers: auth_headers(owner)

      expect(response).to have_http_status(:no_content)
      expect(Retreat.exists?(retreat.id)).to be(false)
    end

    it "refuses to delete a published retreat" do
      retreat = create_retreat(status: "active", published_at: Time.current)

      delete "/api/v1/hotel/retreats/#{retreat.id}", headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Retreat.exists?(retreat.id)).to be(true)
    end
  end

  describe "POST /api/v1/hotel/retreats/:retreat_id/images/batch" do
    it "replaces the gallery and marks the first image as cover" do
      retreat = create_retreat
      retreat.retreat_images.create!(image_url: "https://img.test/old.jpg", position: 0, is_cover: true)

      post "/api/v1/hotel/retreats/#{retreat.id}/images/batch",
           params: { images: [{ image_url: "https://img.test/a.jpg" },
                              { image_url: "https://img.test/b.jpg" }] }.to_json,
           headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      images = retreat.reload.retreat_images.order(:position)
      expect(images.map(&:image_url)).to eq(["https://img.test/a.jpg", "https://img.test/b.jpg"])
      expect(images.first.is_cover).to be(true)
      expect(retreat.cover_image_url).to eq("https://img.test/a.jpg")
    end
  end

  describe "PUT /api/v1/hotel/retreats/:id/program" do
    def existing_program!(retreat)
      day = create(:retreat_day, retreat: retreat, day_number: 1, title: "Old day")
      create(:retreat_activity, retreat_day: day, name: "Old activity")
      retreat.retreat_facilitators.create!(name: "Old Facilitator", role: "lead")
      retreat.retreat_inclusions.create!(name: "Old inclusion")
    end

    it "atomically replaces days, activities, facilitators, and inclusions" do
      retreat = create_retreat
      existing_program!(retreat)

      put "/api/v1/hotel/retreats/#{retreat.id}/program",
          params: {
            days: [{ day_number: 1, title: "Arrival", activities: [{ name: "Opening circle", time: "17:00" }] },
                   { day_number: 2, title: "Immersion", activities: [] }],
            facilitators: [{ name: "Ixchel Nahua", role: "lead", specialty: "Traditional medicine" }],
            inclusions: [{ name: "Plant-based meals" }]
          }.to_json,
          headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      retreat.reload
      expect(retreat.retreat_days.order(:day_number).map(&:title)).to eq(%w[Arrival Immersion])
      expect(retreat.retreat_activities.map(&:name)).to eq(["Opening circle"])
      expect(retreat.retreat_facilitators.map(&:name)).to eq(["Ixchel Nahua"])
      expect(retreat.retreat_inclusions.map(&:name)).to eq(["Plant-based meals"])
    end

    it "rolls back entirely when any record is invalid" do
      retreat = create_retreat
      existing_program!(retreat)

      put "/api/v1/hotel/retreats/#{retreat.id}/program",
          params: {
            days: [{ day_number: 1, title: "Arrival", activities: [{ name: "Opening circle" }] }],
            facilitators: [{ name: "", role: "lead" }],
            inclusions: []
          }.to_json,
          headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_entity)
      retreat.reload
      expect(retreat.retreat_days.map(&:title)).to eq(["Old day"])
      expect(retreat.retreat_activities.map(&:name)).to eq(["Old activity"])
      expect(retreat.retreat_facilitators.map(&:name)).to eq(["Old Facilitator"])
      expect(retreat.retreat_inclusions.map(&:name)).to eq(["Old inclusion"])
    end
  end

  describe "retreat pricing" do
    it "refreshes the cached min price when pricings change" do
      retreat = create_retreat
      suite = create(:room_type, hotel: hotel, name: "Cenote Suite")
      villa = create(:room_type, hotel: hotel, name: "Ocean Villa")

      post "/api/v1/hotel/retreats/#{retreat.id}/pricings",
           params: { retreat_pricing: { room_type_id: suite.id, price_per_guest_cents: 245_000 } }.to_json,
           headers: auth_headers(owner)
      expect(response).to have_http_status(:created)
      expect(retreat.reload.min_price_cents).to eq(245_000)

      post "/api/v1/hotel/retreats/#{retreat.id}/pricings",
           params: { retreat_pricing: { room_type_id: villa.id, price_per_guest_cents: 165_000 } }.to_json,
           headers: auth_headers(owner)
      expect(retreat.reload.min_price_cents).to eq(165_000)

      pricing_id = JSON.parse(response.body)["pricing"]["id"]
      delete "/api/v1/hotel/retreats/#{retreat.id}/pricings/#{pricing_id}", headers: auth_headers(owner)
      expect(retreat.reload.min_price_cents).to eq(245_000)
    end
  end
end
