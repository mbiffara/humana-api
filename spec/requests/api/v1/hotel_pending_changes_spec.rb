require "rails_helper"

# Editing property content after submitting for review (while the org is
# still pending) withdraws the submission until the hotel republishes.
RSpec.describe "Hotel pending changes", type: :request do
  let(:hotel_org) do
    create(:organization, :hotel, status: "pending", onboarding_completed_at: 1.day.ago)
  end
  let(:owner) { create(:user, :owner, organization: hotel_org) }
  let!(:hotel) { create(:hotel, organization: hotel_org) }

  it "flags pending changes when a submitted hotel edits content" do
    patch "/api/v1/hotel/profile",
          params: { hotel: { description: "Updated" } }.to_json,
          headers: auth_headers(owner)

    expect(response).to have_http_status(:ok)
    expect(hotel_org.reload.pending_changes).to be(true)
  end

  it "does not flag before the first submission" do
    hotel_org.update!(onboarding_completed_at: nil)

    patch "/api/v1/hotel/profile",
          params: { hotel: { description: "Updated" } }.to_json,
          headers: auth_headers(owner)

    expect(hotel_org.reload.pending_changes).to be(false)
  end

  it "does not flag approved organizations" do
    hotel_org.update!(status: "verified")

    patch "/api/v1/hotel/profile",
          params: { hotel: { description: "Updated" } }.to_json,
          headers: auth_headers(owner)

    expect(hotel_org.reload.pending_changes).to be(false)
  end

  it "does not flag on reads" do
    get "/api/v1/hotel/profile", headers: auth_headers(owner)
    expect(hotel_org.reload.pending_changes).to be(false)
  end

  it "clears the flag when republishing via submit_for_review" do
    hotel_org.update!(pending_changes: true)

    post "/api/v1/hotel/profile/submit_for_review", headers: auth_headers(owner)

    expect(response).to have_http_status(:ok)
    expect(hotel_org.reload.pending_changes).to be(false)
    expect(hotel_org.onboarding_completed_at).to be_present
  end

  describe "admin feedback (changes requested)" do
    let!(:admin) { create(:user, :admin) }

    it "stores the comment as changes requested on the organization" do
      post "/api/v1/admin/users/#{owner.id}/send_feedback",
           params: { message: "Please add better room photos" }.to_json,
           headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(hotel_org.reload.review_feedback).to eq("Please add better room photos")
      expect(hotel_org.review_feedback_at).to be_present
    end

    it "clears the feedback when the hotel republishes" do
      hotel_org.update!(review_feedback: "Fix photos", review_feedback_at: Time.current)

      post "/api/v1/hotel/profile/submit_for_review", headers: auth_headers(owner)

      expect(hotel_org.reload.review_feedback).to be_nil
      expect(hotel_org.review_feedback_at).to be_nil
    end
  end
end
