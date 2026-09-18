require "rails_helper"

# Verification paperwork (LOG-157) is private. Reading it takes two steps: an
# authenticated call that mints a signature, and a download that travels by
# that signature alone — a browser tab sends no Authorization header.
#
# The organization id lives in the path, so who may read a document is settled
# by where it is stored, never by the hotel-supplied ownership_document_url.
RSpec.describe "Documents", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let(:owner) { create(:user, :owner, organization: hotel_org) }
  let(:other_org) { create(:organization, :hotel, name: "Another Hotel") }
  let(:stranger) { create(:user, :owner, organization: other_org) }
  let(:admin) { create(:user, :admin) }

  let(:name) { "#{SecureRandom.uuid}.pdf" }
  let(:handle) { "http://www.example.com/api/v1/documents/#{hotel_org.id}/#{name}" }
  let(:stored_path) { Rails.root.join("storage", "documents", hotel_org.id.to_s, name) }

  before do
    FileUtils.mkdir_p(stored_path.dirname)
    stored_path.binwrite("%PDF-1.4\n%%EOF\n")
  end

  after { FileUtils.rm_rf(Rails.root.join("storage", "documents")) }

  def request_link(url, user)
    post "/api/v1/documents/link", params: { url: url }.to_json, headers: auth_headers(user)
  end

  describe "POST /api/v1/documents/link" do
    it "signs a link for the organization the document belongs to" do
      request_link(handle, owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["url"]).to start_with("#{handle}?token=")
    end

    it "signs a link for a platform admin reviewing the property" do
      request_link(handle, admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["url"]).to include("token=")
    end

    it "refuses another organization's document" do
      request_link(handle, stranger)

      expect(response).to have_http_status(:forbidden)
    end

    # The whole point of the id in the path: claiming the handle is not enough.
    it "refuses it even when the caller stored that handle as its own" do
      other_org.update_column(:ownership_document_url, handle)

      request_link(handle, stranger)

      expect(response).to have_http_status(:forbidden)
    end

    it "does not recognize a URL whose path is not a document handle" do
      request_link("https://evil.example.com/files/#{name}", owner)

      expect(response).to have_http_status(:not_found)
    end

    it "does not recognize a handle with no organization in the path" do
      request_link("http://www.example.com/api/v1/documents/#{name}", owner)

      expect(response).to have_http_status(:not_found)
    end

    it "does not recognize a handle whose name is not ours" do
      request_link("http://www.example.com/api/v1/documents/#{hotel_org.id}/../../config/database.yml", owner)

      expect(response).to have_http_status(:not_found)
    end

    # Host and scheme drift over the life of a deployment; a handle stored
    # before the drift still points at the same document.
    it "still resolves a handle stored under another host and scheme" do
      request_link("https://otro-host/api/v1/documents/#{hotel_org.id}/#{name}", owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["url"]).to start_with("#{handle}?token=")
    end

    it "requires authentication" do
      post "/api/v1/documents/link", params: { url: handle }.to_json,
                                     headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/documents/:org_id/:name" do
    def signed_url(user = owner, url = handle)
      request_link(url, user)
      response.parsed_body["url"]
    end

    it "serves the document inline and tells caches to keep it to themselves" do
      get signed_url

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("inline")
      expect(response.headers["Cache-Control"]).to eq("private, no-store")
    end

    it "refuses a request with no token at all" do
      get "/api/v1/documents/#{hotel_org.id}/#{name}"

      expect(response).to have_http_status(:forbidden)
    end

    it "refuses an expired token" do
      url = signed_url

      travel(11.minutes) { get url }

      expect(response).to have_http_status(:forbidden)
    end

    it "refuses a token signed for a different document" do
      other = "#{SecureRandom.uuid}.pdf"
      token = signed_url(owner, "http://www.example.com/api/v1/documents/#{hotel_org.id}/#{other}")
                .split("token=").last

      get "/api/v1/documents/#{hotel_org.id}/#{name}?token=#{token}"

      expect(response).to have_http_status(:forbidden)
    end

    # A token minted for one organization must not open another one's file,
    # even when the file name is the same.
    it "refuses a token signed for another organization" do
      twin = Rails.root.join("storage", "documents", other_org.id.to_s, name)
      FileUtils.mkdir_p(twin.dirname)
      twin.binwrite("%PDF-1.4\n%%EOF\n")
      token = signed_url(stranger, "http://www.example.com/api/v1/documents/#{other_org.id}/#{name}")
                .split("token=").last

      get "/api/v1/documents/#{hotel_org.id}/#{name}?token=#{token}"

      expect(response).to have_http_status(:forbidden)
    end

    it "refuses a made-up token" do
      get "/api/v1/documents/#{hotel_org.id}/#{name}?token=not-a-signature"

      expect(response).to have_http_status(:forbidden)
    end

    it "does not recognize a name outside the stored shape" do
      get "/api/v1/documents/#{hotel_org.id}/database.yml?token=whatever"

      expect(response).to have_http_status(:not_found)
    end

    it "does not recognize a name with an extension we never store" do
      get "/api/v1/documents/#{hotel_org.id}/#{SecureRandom.uuid}.rb?token=whatever"

      expect(response).to have_http_status(:not_found)
    end

    it "reports a signed name that is no longer on disk as missing" do
      url = signed_url
      File.delete(stored_path)

      get url

      expect(response).to have_http_status(:not_found)
    end
  end
end
