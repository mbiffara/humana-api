require "rails_helper"

# Common spaces section (LOG-143): the halls, yoga rooms, terraces and gardens
# a hotel can offer to a retreat group, each with its own gallery.
RSpec.describe "Hotel Common Spaces API", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let(:owner) { create(:user, :owner, organization: hotel_org) }
  let!(:hotel) { create(:hotel, organization: hotel_org) }

  def create_space(attrs)
    post "/api/v1/hotel/common_spaces",
         params: { common_space: attrs }.to_json,
         headers: auth_headers(owner)
  end

  describe "POST /api/v1/hotel/common_spaces" do
    it "creates a space with its capacities, floor and equipment" do
      create_space(
        name: "Salón Sol",
        space_type: "salon",
        capacity_seated: 80,
        capacity_banquet: 60,
        area_sqm: 120,
        floor_type: "wood",
        exclusive_for_groups: true,
        equipment: %w[projector sound wifi]
      )

      expect(response).to have_http_status(:created)
      body = response.parsed_body["common_space"]
      expect(body).to include(
        "name" => "Salón Sol",
        "space_type" => "salon",
        "space_type_other" => nil,
        "capacity_seated" => 80,
        "capacity_yoga" => nil,
        "capacity_banquet" => 60,
        "capacity_workshop" => nil,
        "area_sqm" => 120.0,
        "floor_type" => "wood",
        "floor_type_other" => nil,
        "exclusive_for_groups" => true,
        "equipment" => %w[projector sound wifi],
        "equipment_other" => nil,
        "hotel_id" => hotel.id,
        "position" => 0,
        "image_url" => nil,
        "images" => []
      )
      expect(hotel.common_spaces.count).to eq(1)
    end

    it "appends each new space after the previous one" do
      create_space(name: "Salón Sol", space_type: "salon")
      create_space(name: "Terraza", space_type: "terrace")

      expect(hotel.common_spaces.ordered.map(&:position)).to eq([0, 1])
    end

    it "rejects an unknown space type" do
      create_space(name: "Gimnasio", space_type: "gym")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(hotel.common_spaces.count).to eq(0)
    end

    it "requires the free-text label when the type is other" do
      create_space(name: "Cueva", space_type: "other")
      expect(response).to have_http_status(:unprocessable_entity)

      create_space(name: "Cueva", space_type: "other", space_type_other: "Cueva de sal")
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["common_space"]["space_type_other"]).to eq("Cueva de sal")
    end

    it "rejects unknown equipment" do
      create_space(name: "Salón Sol", space_type: "salon", equipment: ["laser"])

      expect(response).to have_http_status(:unprocessable_entity)
      expect(hotel.common_spaces.count).to eq(0)
    end
  end

  describe "GET /api/v1/hotel/common_spaces" do
    it "lists only the authenticated hotel's spaces, ordered" do
      create(:common_space, hotel: hotel, name: "Terraza", space_type: "terrace", position: 1)
      create(:common_space, hotel: hotel, name: "Salón Sol", position: 0)
      create(:common_space, name: "Salón ajeno")

      get "/api/v1/hotel/common_spaces", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      spaces = response.parsed_body["common_spaces"]
      expect(spaces.map { |s| s["name"] }).to eq(["Salón Sol", "Terraza"])
    end
  end

  describe "GET/PATCH/DELETE /api/v1/hotel/common_spaces/:id" do
    let!(:space) { create(:common_space, hotel: hotel, name: "Salón Sol") }

    it "shows the space with its gallery" do
      space.common_space_images.create!(image_url: "https://img.test/a.jpg", position: 0, is_primary: true)

      get "/api/v1/hotel/common_spaces/#{space.id}", headers: auth_headers(owner)

      body = response.parsed_body["common_space"]
      expect(body["image_url"]).to eq("https://img.test/a.jpg")
      expect(body["images"].first).to include("is_primary" => true, "position" => 0)
    end

    it "updates the space" do
      patch "/api/v1/hotel/common_spaces/#{space.id}",
            params: { common_space: { capacity_yoga: 25, floor_type: "floating",
                                      equipment: %w[yoga_mats lighting] } }.to_json,
            headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body["common_space"]
      expect(body["capacity_yoga"]).to eq(25)
      expect(body["floor_type"]).to eq("floating")
      expect(body["equipment"]).to eq(%w[yoga_mats lighting])
    end

    it "drops the free-text labels when their option stops being selected" do
      create_space(name: "Carpa", space_type: "other", space_type_other: "Carpa",
                   floor_type: "other", floor_type_other: "Arena",
                   equipment: ["other"], equipment_other: "Telas")
      expect(response).to have_http_status(:created)
      created = response.parsed_body["common_space"]
      expect(created).to include("space_type_other" => "Carpa", "floor_type_other" => "Arena",
                                 "equipment_other" => "Telas")

      patch "/api/v1/hotel/common_spaces/#{created['id']}",
            params: { common_space: { space_type: "salon", floor_type: "wood",
                                      equipment: ["wifi"] } }.to_json,
            headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body["common_space"]
      expect(body).to include("space_type" => "salon", "space_type_other" => nil,
                              "floor_type" => "wood", "floor_type_other" => nil,
                              "equipment" => ["wifi"], "equipment_other" => nil)

      stored = CommonSpace.find(created["id"])
      expect([stored.space_type_other, stored.floor_type_other, stored.equipment_other]).to all(be_nil)
    end

    it "deletes the space and its images" do
      space.common_space_images.create!(image_url: "https://img.test/a.jpg", position: 0, is_primary: true)

      delete "/api/v1/hotel/common_spaces/#{space.id}", headers: auth_headers(owner)

      expect(response).to have_http_status(:no_content)
      expect(CommonSpace.where(id: space.id)).to be_empty
      expect(CommonSpaceImage.count).to eq(0)
    end

    it "returns 404 for another hotel's space" do
      foreign = create(:common_space)

      get "/api/v1/hotel/common_spaces/#{foreign.id}", headers: auth_headers(owner)
      expect(response).to have_http_status(:not_found)

      patch "/api/v1/hotel/common_spaces/#{foreign.id}",
            params: { common_space: { name: "Robado" } }.to_json,
            headers: auth_headers(owner)
      expect(response).to have_http_status(:not_found)

      delete "/api/v1/hotel/common_spaces/#{foreign.id}", headers: auth_headers(owner)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/hotel/common_spaces/:id/images/batch" do
    let!(:space) { create(:common_space, hotel: hotel, name: "Salón Sol") }

    def batch(images, target: space)
      post "/api/v1/hotel/common_spaces/#{target.id}/images/batch",
           params: { images: images }.to_json,
           headers: auth_headers(owner)
    end

    it "replaces the gallery in order and flags the first image as primary" do
      space.common_space_images.create!(image_url: "https://img.test/old.jpg", position: 0, is_primary: true)

      batch([
        { image_url: "https://img.test/a.jpg", alt_text: "Vista" },
        { image_url: "https://img.test/b.jpg" },
        { image_url: "https://img.test/c.jpg" }
      ])

      expect(response).to have_http_status(:created)
      images = space.reload.common_space_images.ordered
      expect(images.map(&:image_url)).to eq(["https://img.test/a.jpg", "https://img.test/b.jpg", "https://img.test/c.jpg"])
      expect(images.map(&:position)).to eq([0, 1, 2])
      expect(images.map(&:is_primary)).to eq([true, false, false])
      expect(response.parsed_body["images"].first.keys)
        .to match_array(%w[id image_url position is_primary alt_text])
    end

    it "lists the gallery" do
      batch([{ image_url: "https://img.test/a.jpg" }])

      get "/api/v1/hotel/common_spaces/#{space.id}/images", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["images"].map { |i| i["image_url"] }).to eq(["https://img.test/a.jpg"])
    end

    it "rejects more than eight images and leaves the gallery untouched" do
      space.common_space_images.create!(image_url: "https://img.test/old.jpg", position: 0, is_primary: true)

      batch((1..9).map { |n| { image_url: "https://img.test/#{n}.jpg" } })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Up to 8 images per space")
      expect(space.reload.common_space_images.map(&:image_url)).to eq(["https://img.test/old.jpg"])
    end

    it "rolls back entirely when any image is invalid" do
      space.common_space_images.create!(image_url: "https://img.test/old.jpg", position: 0, is_primary: true)

      batch([{ image_url: "https://img.test/a.jpg" }, { image_url: "" }])

      expect(response).to have_http_status(:unprocessable_entity)
      expect(space.reload.common_space_images.map(&:image_url)).to eq(["https://img.test/old.jpg"])
    end

    it "returns 404 for another hotel's space" do
      batch([{ image_url: "https://img.test/a.jpg" }], target: create(:common_space))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "public hotel profile" do
    it "carries the common spaces with their images" do
      space = create(:common_space, hotel: hotel, name: "Salón Sol", capacity_seated: 80,
                                    equipment: %w[projector wifi])
      space.common_space_images.create!(image_url: "https://img.test/a.jpg", position: 0, is_primary: true)

      get "/api/v1/public/hotels/#{hotel.id}"

      expect(response).to have_http_status(:ok)
      spaces = response.parsed_body["hotel"]["common_spaces"]
      expect(spaces.length).to eq(1)
      expect(spaces.first).to include("name" => "Salón Sol", "capacity_seated" => 80,
                                      "equipment" => %w[projector wifi],
                                      "image_url" => "https://img.test/a.jpg")
      expect(spaces.first["images"].map { |i| i["image_url"] }).to eq(["https://img.test/a.jpg"])
    end

    it "is an empty list for a hotel with no spaces" do
      get "/api/v1/public/hotels/#{hotel.id}"

      expect(response.parsed_body["hotel"]["common_spaces"]).to eq([])
    end
  end

  describe "access control" do
    it "denies an agency user" do
      agency_user = create(:user, :owner, organization: create(:organization))

      get "/api/v1/hotel/common_spaces", headers: auth_headers(agency_user)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
