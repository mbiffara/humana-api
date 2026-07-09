require "rails_helper"

RSpec.describe Country, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      country = build(:country)
      expect(country).to be_valid
    end

    it "requires a name" do
      country = build(:country, name: nil)
      expect(country).not_to be_valid
    end

    it "requires a unique code" do
      create(:country, code: "ES")
      country = build(:country, code: "ES")
      expect(country).not_to be_valid
    end

    it "uppercases the code before validation" do
      country = create(:country, code: "es")
      expect(country.code).to eq("ES")
    end
  end

  describe "scopes" do
    it ".active returns only active countries" do
      active = create(:country, status: "active")
      create(:country, status: "inactive")
      expect(Country.active).to eq([active])
    end

    it ".enabled returns only enabled countries" do
      enabled = create(:country, enabled: true)
      create(:country, enabled: false)
      expect(Country.enabled).to eq([enabled])
    end

    it ".by_region filters by region" do
      europe = create(:country, region: "Europe")
      create(:country, region: "LATAM")
      expect(Country.by_region("Europe")).to eq([europe])
    end
  end
end
