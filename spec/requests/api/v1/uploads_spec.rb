require "rails_helper"

# The upload endpoint serves two audiences. Property photography is images
# only; the verification block (LOG-157) also uploads paperwork, which arrives
# as a PDF under `kind=document` and lands on its own prefix.
RSpec.describe "Uploads", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let(:owner) { create(:user, :owner, organization: hotel_org) }

  # A minimal but structurally real PDF, so the request carries actual bytes.
  def pdf_file
    path = Rails.root.join("tmp", "log157-#{SecureRandom.hex(4)}.pdf")
    path.binwrite("%PDF-1.4\n1 0 obj<</Type/Catalog>>endobj\ntrailer<</Root 1 0 R>>\n%%EOF\n")
    @pdf_paths << path
    Rack::Test::UploadedFile.new(path, "application/pdf")
  end

  def jpeg_file
    path = Rails.root.join("tmp", "log157-#{SecureRandom.hex(4)}.jpg")
    path.binwrite("\xFF\xD8\xFF\xE0".b + ("\x00".b * 32))
    @pdf_paths << path
    Rack::Test::UploadedFile.new(path, "image/jpeg")
  end

  def upload_headers
    auth_headers(owner).except("Content-Type")
  end

  before { @pdf_paths = [] }

  after do
    @pdf_paths.each { |p| File.delete(p) if File.exist?(p) }
    FileUtils.rm_rf(Rails.root.join("public", "documents"))
  end

  it "rejects a PDF sent without a kind" do
    post "/api/v1/uploads", params: { file: pdf_file }, headers: upload_headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body["error"]).to eq("Invalid file type. Allowed: JPEG, PNG, WebP")
  end

  it "accepts a PDF as a document and files it under documents/" do
    post "/api/v1/uploads", params: { file: pdf_file, kind: "document" }, headers: upload_headers

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["url"]).to include("documents/")
    expect(response.parsed_body["url"]).to end_with(".pdf")
  end

  it "still accepts a JPEG without a kind and files it under uploads/" do
    post "/api/v1/uploads", params: { file: jpeg_file }, headers: upload_headers

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["url"]).to include("uploads/")
  end

  it "accepts a JPEG as a document too — a photo of the deed still counts" do
    post "/api/v1/uploads", params: { file: jpeg_file, kind: "document" }, headers: upload_headers

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["url"]).to include("documents/")
  end

  it "requires authentication" do
    post "/api/v1/uploads", params: { file: pdf_file, kind: "document" }

    expect(response).to have_http_status(:unauthorized)
  end
end
