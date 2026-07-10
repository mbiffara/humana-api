require "rails_helper"

RSpec.describe RoomType, type: :model do
  let(:hotel) { create(:hotel) }

  describe "validations" do
    it "is valid with valid attributes" do
      rt = build(:room_type, hotel: hotel)
      expect(rt).to be_valid
    end

    it "requires a name" do
      rt = build(:room_type, hotel: hotel, name: nil)
      expect(rt).not_to be_valid
    end

    it "requires unique name per hotel" do
      create(:room_type, hotel: hotel, name: "Suite")
      rt = build(:room_type, hotel: hotel, name: "Suite")
      expect(rt).not_to be_valid
    end

    it "requires a valid category" do
      rt = build(:room_type, hotel: hotel, category: "invalid")
      expect(rt).not_to be_valid
    end
  end

  describe "#price_per_night" do
    it "converts cents to dollars" do
      rt = build(:room_type, price_per_night_cents: 25000)
      expect(rt.price_per_night).to eq(250.0)
    end
  end
end
