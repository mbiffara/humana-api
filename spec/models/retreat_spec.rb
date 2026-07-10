require "rails_helper"

RSpec.describe Retreat, type: :model do
  let(:hotel) { create(:hotel) }

  describe "validations" do
    it "is valid with valid attributes" do
      retreat = build(:retreat, hotel: hotel, created_by_organization: hotel.organization)
      expect(retreat).to be_valid
    end

    it "requires a name" do
      retreat = build(:retreat, hotel: hotel, created_by_organization: hotel.organization, name: nil)
      expect(retreat).not_to be_valid
    end

    it "requires a valid retreat_type" do
      retreat = build(:retreat, hotel: hotel, created_by_organization: hotel.organization, retreat_type: "invalid")
      expect(retreat).not_to be_valid
    end

    it "requires a valid status" do
      retreat = build(:retreat, hotel: hotel, created_by_organization: hotel.organization, status: "invalid")
      expect(retreat).not_to be_valid
    end
  end

  describe "slug generation" do
    it "auto-generates a slug from name" do
      retreat = create(:retreat, hotel: hotel, created_by_organization: hotel.organization, name: "My Wellness Retreat")
      expect(retreat.slug).to eq("my-wellness-retreat")
    end

    it "generates unique slugs" do
      r1 = create(:retreat, hotel: hotel, created_by_organization: hotel.organization, name: "Retreat")
      r2 = create(:retreat, hotel: hotel, created_by_organization: hotel.organization, name: "Retreat")
      expect(r1.slug).not_to eq(r2.slug)
    end
  end

  describe "#publish!" do
    it "sets status to active and published_at" do
      retreat = create(:retreat, hotel: hotel, created_by_organization: hotel.organization)
      retreat.publish!
      expect(retreat.status).to eq("active")
      expect(retreat.published_at).to be_present
    end
  end

  describe "scopes" do
    it ".published returns active and upcoming" do
      active = create(:retreat, :active, hotel: hotel, created_by_organization: hotel.organization)
      upcoming = create(:retreat, :upcoming, hotel: hotel, created_by_organization: hotel.organization)
      create(:retreat, hotel: hotel, created_by_organization: hotel.organization, status: "draft")
      expect(Retreat.published).to contain_exactly(active, upcoming)
    end

    it ".featured returns only featured" do
      featured = create(:retreat, :active, :featured, hotel: hotel, created_by_organization: hotel.organization)
      create(:retreat, :active, hotel: hotel, created_by_organization: hotel.organization)
      expect(Retreat.featured).to eq([featured])
    end
  end
end
