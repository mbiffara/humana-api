require "rails_helper"

RSpec.describe Invitation, type: :model do
  let(:org) { create(:organization) }
  let(:admin) { create(:user, :admin) }

  describe "validations" do
    it "is valid with valid attributes" do
      invitation = build(:invitation, organization: org, invited_by: admin)
      expect(invitation).to be_valid
    end

    it "requires a valid email" do
      invitation = build(:invitation, email: "not-an-email", organization: org, invited_by: admin)
      expect(invitation).not_to be_valid
    end

    it "requires a valid role" do
      invitation = build(:invitation, role: "superuser", organization: org, invited_by: admin)
      expect(invitation).not_to be_valid
    end
  end

  describe "token generation" do
    it "auto-generates a token on create" do
      invitation = create(:invitation, organization: org, invited_by: admin)
      expect(invitation.token).to be_present
      expect(invitation.token.length).to be >= 32
    end

    it "generates unique tokens" do
      inv1 = create(:invitation, organization: org, invited_by: admin)
      inv2 = create(:invitation, organization: org, invited_by: admin)
      expect(inv1.token).not_to eq(inv2.token)
    end
  end

  describe "expiry" do
    it "sets expires_at to 48 hours from creation" do
      invitation = create(:invitation, organization: org, invited_by: admin)
      expect(invitation.expires_at).to be_within(1.minute).of(48.hours.from_now)
    end

    it "#expired? returns true for past expiry" do
      invitation = create(:invitation, organization: org, invited_by: admin)
      invitation.update!(expires_at: 1.hour.ago)
      expect(invitation).to be_expired
    end

    it "#expired? returns false for future expiry" do
      invitation = create(:invitation, organization: org, invited_by: admin)
      expect(invitation).not_to be_expired
    end
  end

  describe "#accepted?" do
    it "returns false when not accepted" do
      invitation = create(:invitation, organization: org, invited_by: admin)
      expect(invitation).not_to be_accepted
    end

    it "returns true when accepted" do
      invitation = create(:invitation, organization: org, invited_by: admin, accepted_at: Time.current)
      expect(invitation).to be_accepted
    end
  end

  describe "#magic_link" do
    it "generates a link with the token" do
      invitation = create(:invitation, organization: org, invited_by: admin)
      expect(invitation.magic_link).to include("/accept-invite?token=#{invitation.token}")
    end
  end
end
