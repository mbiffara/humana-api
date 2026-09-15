require "rails_helper"

# Property photo gallery for the onboarding photo step (LOG-137): each image
# carries a category and exactly one of them is the cover.
RSpec.describe "Hotel Images API", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let(:owner) { create(:user, :owner, organization: hotel_org) }
  let!(:hotel) { create(:hotel, organization: hotel_org) }

  def batch(images)
    post "/api/v1/hotel/images/batch",
         params: { images: images }.to_json,
         headers: auth_headers(owner)
  end

  describe "POST /api/v1/hotel/images/batch" do
    it "replaces the gallery keeping each category and the submitted order" do
      batch([
        { image_url: "https://img.test/a.jpg", category: "common_area" },
        { image_url: "https://img.test/b.jpg", category: "spa" },
        { image_url: "https://img.test/c.jpg", category: "exterior" }
      ])

      expect(response).to have_http_status(:created)
      images = hotel.reload.hotel_images.ordered
      expect(images.map(&:image_url)).to eq(["https://img.test/a.jpg", "https://img.test/b.jpg", "https://img.test/c.jpg"])
      expect(images.map(&:category)).to eq(%w[common_area spa exterior])
      expect(images.map(&:position)).to eq([0, 1, 2])

      body = response.parsed_body["images"]
      expect(body.first.keys).to match_array(%w[id image_url category position is_cover alt_text])
    end

    it "defaults a missing category to general" do
      batch([{ image_url: "https://img.test/a.jpg" }])

      expect(response).to have_http_status(:created)
      expect(hotel.reload.hotel_images.first.category).to eq("general")
    end

    it "rejects an unknown category and leaves the gallery untouched" do
      hotel.hotel_images.create!(image_url: "https://img.test/old.jpg", category: "exterior", position: 0, is_cover: true)

      batch([
        { image_url: "https://img.test/a.jpg", category: "spa" },
        { image_url: "https://img.test/b.jpg", category: "cocina" }
      ])

      expect(response).to have_http_status(:unprocessable_entity)
      images = hotel.reload.hotel_images.ordered
      expect(images.map(&:image_url)).to eq(["https://img.test/old.jpg"])
      expect(images.first.category).to eq("exterior")
    end

    it "makes the first image the cover when none is flagged" do
      batch([
        { image_url: "https://img.test/a.jpg", category: "exterior" },
        { image_url: "https://img.test/b.jpg", category: "spa" }
      ])

      expect(hotel.reload.hotel_images.ordered.map(&:is_cover)).to eq([true, false])
      expect(hotel.cover_image.image_url).to eq("https://img.test/a.jpg")
    end

    it "honours an explicit cover and reflects it in cover_image_url" do
      batch([
        { image_url: "https://img.test/a.jpg", category: "exterior" },
        { image_url: "https://img.test/b.jpg", category: "spa", is_cover: true }
      ])

      expect(hotel.reload.hotel_images.ordered.map(&:is_cover)).to eq([false, true])

      get "/api/v1/hotel/profile", headers: auth_headers(owner)
      expect(response.parsed_body["hotel"]["cover_image_url"]).to eq("https://img.test/b.jpg")
    end

    it "keeps only the first image flagged as cover" do
      batch([
        { image_url: "https://img.test/a.jpg", category: "exterior" },
        { image_url: "https://img.test/b.jpg", category: "spa", is_cover: true },
        { image_url: "https://img.test/c.jpg", category: "pool", is_cover: true }
      ])

      expect(hotel.reload.hotel_images.ordered.map(&:is_cover)).to eq([false, true, false])
      expect(hotel.cover_image.image_url).to eq("https://img.test/b.jpg")
    end
  end

  describe "GET /api/v1/hotel/images" do
    it "returns the gallery in position order with the full contract" do
      hotel.hotel_images.create!(image_url: "https://img.test/b.jpg", category: "spa", position: 1)
      hotel.hotel_images.create!(image_url: "https://img.test/a.jpg", category: "exterior", position: 0,
                                 is_cover: true, alt_text: "Front view")

      get "/api/v1/hotel/images", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      images = response.parsed_body["images"]
      expect(images.map { |i| i["image_url"] }).to eq(["https://img.test/a.jpg", "https://img.test/b.jpg"])
      expect(images.first).to include("category" => "exterior", "is_cover" => true, "alt_text" => "Front view")
    end
  end
end
