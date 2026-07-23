require "rails_helper"

RSpec.describe Room, type: :model do
  let(:hotel) { create(:hotel) }
  let(:room_type) { create(:room_type, hotel: hotel) }

  it "is valid with a number, hotel and room type" do
    expect(build(:room, room_type: room_type)).to be_valid
  end

  it "requires a number" do
    expect(build(:room, room_type: room_type, number: "")).not_to be_valid
  end

  it "rejects duplicate numbers within the same hotel, case-insensitively" do
    create(:room, room_type: room_type, number: "Suite 1")
    other_type = create(:room_type, hotel: hotel)
    dup = build(:room, room_type: other_type, number: "suite 1")
    expect(dup).not_to be_valid
    expect(dup.errors[:number]).to be_present
  end

  it "allows the same number in a different hotel" do
    create(:room, room_type: room_type, number: "101")
    expect(build(:room, number: "101")).to be_valid
  end

  it "rejects a room type from another hotel" do
    foreign_type = create(:room_type)
    room = build(:room, hotel: hotel, room_type: foreign_type)
    expect(room).not_to be_valid
    expect(room.errors[:room_type]).to be_present
  end

  it "rejects unknown statuses" do
    expect(build(:room, room_type: room_type, status: "haunted")).not_to be_valid
  end
end

RSpec.describe RoomType, "#sync_rooms_with_total" do
  let(:hotel) { create(:hotel) }

  it "auto-creates rooms to match total_rooms" do
    rt = create(:room_type, hotel: hotel, name: "Suite", total_rooms: 3)
    expect(rt.rooms.count).to eq(3)
    expect(rt.rooms.pluck(:number)).to contain_exactly("Suite 1", "Suite 2", "Suite 3")
    expect(rt.rooms.pluck(:auto_generated).uniq).to eq([true])
  end

  it "tops up rooms when total_rooms grows" do
    rt = create(:room_type, hotel: hotel, name: "Villa", total_rooms: 1)
    rt.update!(total_rooms: 3)
    expect(rt.rooms.count).to eq(3)
  end

  it "skips numbers already taken in the hotel" do
    rt = create(:room_type, hotel: hotel, name: "Suite")
    create(:room, hotel: hotel, room_type: rt, number: "Suite 1")
    rt.update!(total_rooms: 2)
    expect(rt.rooms.pluck(:number)).to contain_exactly("Suite 1", "Suite 2")
  end

  it "removes auto-generated rooms when total_rooms shrinks" do
    rt = create(:room_type, hotel: hotel, total_rooms: 4)
    rt.update!(total_rooms: 2)
    expect(rt.rooms.count).to eq(2)
  end

  it "keeps manually created rooms and corrects total_rooms when it cannot shrink" do
    rt = create(:room_type, hotel: hotel, total_rooms: 0)
    create(:room, hotel: hotel, room_type: rt, number: "Penthouse A")
    create(:room, hotel: hotel, room_type: rt, number: "Penthouse B")
    rt.update!(total_rooms: 1)
    expect(rt.rooms.count).to eq(2)
    expect(rt.reload.total_rooms).to eq(2)
  end
end
