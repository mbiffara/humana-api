require "rails_helper"

RSpec.describe Booking, "availability check" do
  let(:hotel_org) { create(:organization, :hotel) }
  let!(:hotel) { create(:hotel, organization: hotel_org) }
  let(:room_type) { create(:room_type, hotel: hotel, name: "Suite") }
  let(:agency) { create(:organization) }
  let(:experience) { create(:experience, hotel: hotel) }

  def build_booking(**attrs)
    build(:booking, organization: agency, experience: experience, room_type: room_type,
                    starts_on: Date.current, ends_on: Date.current + 3, **attrs)
  end

  context "with tracked inventory" do
    before { create(:room, room_type: room_type, number: "Suite 1") }

    it "rejects a booking when all units are taken" do
      create(:booking, organization: agency, experience: experience, room_type: room_type,
                       starts_on: Date.current, ends_on: Date.current + 3)

      booking = build_booking
      expect(booking).not_to be_valid
      expect(booking.errors[:room_type]).to include("has no availability for the selected dates")
    end

    it "allows back-to-back bookings (checkout-exclusive nights)" do
      create(:booking, organization: agency, experience: experience, room_type: room_type,
                       starts_on: Date.current, ends_on: Date.current + 3)

      expect(build_booking(starts_on: Date.current + 3, ends_on: Date.current + 5)).to be_valid
    end

    it "rejects a booking when an availability block closes the inventory" do
      create(:availability_block, hotel: hotel, room_type: room_type,
                                  starts_on: Date.current + 1, ends_on: Date.current + 1)

      expect(build_booking).not_to be_valid
    end

    it "frees inventory when the competing booking is cancelled" do
      create(:booking, organization: agency, experience: experience, room_type: room_type,
                       starts_on: Date.current, ends_on: Date.current + 3, status: "cancelled")

      expect(build_booking).to be_valid
    end

    it "keeps existing bookings updatable when inventory later disappears" do
      booking = build_booking
      booking.save!
      create(:availability_block, hotel: hotel, room_type: room_type,
                                  starts_on: Date.current, ends_on: Date.current + 10)

      booking.status = "completed"
      expect(booking).to be_valid
    end

    it "re-checks when the dates change" do
      booking = build_booking
      booking.save!
      create(:availability_block, hotel: hotel, room_type: room_type,
                                  starts_on: Date.current + 10, ends_on: Date.current + 20)

      booking.assign_attributes(starts_on: Date.current + 10, ends_on: Date.current + 12)
      expect(booking).not_to be_valid
    end
  end

  it "skips enforcement for room types without physical rooms" do
    expect(build_booking).to be_valid
  end
end
