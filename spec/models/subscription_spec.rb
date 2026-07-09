require "rails_helper"

RSpec.describe Subscription, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      sub = build(:subscription)
      expect(sub).to be_valid
    end

    it "requires a valid status" do
      sub = build(:subscription, status: "invalid")
      expect(sub).not_to be_valid
    end
  end

  describe "#active?" do
    it "returns true for active and trialing" do
      expect(build(:subscription, status: "active").active?).to be true
      expect(build(:subscription, status: "trialing").active?).to be true
    end

    it "returns false for cancelled" do
      expect(build(:subscription, status: "cancelled").active?).to be false
    end
  end

  describe "#days_remaining_in_trial" do
    it "returns days left in trial" do
      sub = build(:subscription, :trialing, trial_ends_at: 10.days.from_now)
      expect(sub.days_remaining_in_trial).to eq(10)
    end

    it "returns 0 when not trialing" do
      sub = build(:subscription, status: "active")
      expect(sub.days_remaining_in_trial).to eq(0)
    end
  end
end
