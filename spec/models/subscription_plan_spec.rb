require "rails_helper"

RSpec.describe SubscriptionPlan, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      plan = build(:subscription_plan)
      expect(plan).to be_valid
    end

    it "requires a name" do
      plan = build(:subscription_plan, name: nil)
      expect(plan).not_to be_valid
    end

    it "requires valid billing_interval" do
      plan = build(:subscription_plan, billing_interval: "weekly")
      expect(plan).not_to be_valid
    end
  end

  describe "slug generation" do
    it "auto-generates a slug from name" do
      plan = create(:subscription_plan, name: "Professional Plus")
      expect(plan.slug).to eq("professional-plus")
    end
  end

  describe "#commission_percent" do
    it "converts rate to percentage" do
      plan = build(:subscription_plan, commission_rate: 0.14)
      expect(plan.commission_percent).to eq(14)
    end
  end

  describe "scopes" do
    it ".active returns only active plans" do
      active = create(:subscription_plan, active: true)
      create(:subscription_plan, active: false)
      expect(SubscriptionPlan.active).to eq([active])
    end
  end
end
