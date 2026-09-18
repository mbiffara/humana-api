require "rails_helper"

# The upload endpoint serves two audiences. Property photography is images
# only, stays public and keeps its URL. Verification paperwork (LOG-157)
# arrives under `kind=document`, lands outside the public tree and comes back
# as a handle that only Api::V1::DocumentsController can turn into a link.
RSpec.describe "Uploads", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let(:owner) { create(:user, :owner, organization: hotel_org) }

  # A minimal but structurally real PDF, so the request carries actual bytes.
  # The extension of the local file is deliberately wrong in some examples —
  # the stored name must come from the content type, not from this one.
  def upload(content_type, filename)
    path = Rails.root.join("tmp", filename.sub(".", "-#{SecureRandom.hex(4)}."))
    path.binwrite("%PDF-1.4\n1 0 obj<</Type/Catalog>>endobj\ntrailer<</Root 1 0 R>>\n%%EOF\n")
    @tmp_paths << path
    Rack::Test::UploadedFile.new(path, content_type)
  end

  def pdf_file(filename = "deed.pdf") = upload("application/pdf", filename)
  def jpeg_file(filename = "photo.jpg") = upload("image/jpeg", filename)

  def upload_headers = auth_headers(owner).except("Content-Type")

  def document_name(url) = url.split("/api/v1/documents/").last

  before { @tmp_paths = [] }

  after do
    @tmp_paths.each { |p| File.delete(p) if File.exist?(p) }
    FileUtils.rm_rf(Rails.root.join("storage", "documents"))
  end

  it "rejects a PDF sent without a kind" do
    post "/api/v1/uploads", params: { file: pdf_file }, headers: upload_headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body["error"]).to eq("Invalid file type. Allowed: JPEG, PNG, WebP")
  end

  it "returns a documents handle instead of a readable URL" do
    post "/api/v1/uploads", params: { file: pdf_file, kind: "document" }, headers: upload_headers

    expect(response).to have_http_status(:created)
    url = response.parsed_body["url"]
    expect(url).to start_with("http://www.example.com/api/v1/documents/")
    expect(document_name(url)).to match(/\A[0-9a-f-]{36}\.pdf\z/)
  end

  it "stores the document outside the public tree" do
    post "/api/v1/uploads", params: { file: pdf_file, kind: "document" }, headers: upload_headers

    name = document_name(response.parsed_body["url"])
    expect(File).to exist(Rails.root.join("storage", "documents", name))
    expect(File).not_to exist(Rails.root.join("public", "documents", name))
    expect(File).not_to exist(Rails.root.join("public", "uploads", name))
  end

  it "takes the extension from the content type, not from the file name" do
    post "/api/v1/uploads",
         params: { file: upload("application/pdf", "deed.jpg.exe"), kind: "document" },
         headers: upload_headers

    expect(response).to have_http_status(:created)
    expect(document_name(response.parsed_body["url"])).to end_with(".pdf")
  end

  it "accepts the kind from the query string too" do
    post "/api/v1/uploads?kind=document", params: { file: pdf_file }, headers: upload_headers

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["url"]).to include("/api/v1/documents/")
  end

  it "accepts a JPEG as a document too — a photo of the deed still counts" do
    post "/api/v1/uploads", params: { file: jpeg_file, kind: "document" }, headers: upload_headers

    expect(response).to have_http_status(:created)
    expect(document_name(response.parsed_body["url"])).to end_with(".jpg")
  end

  it "leaves image uploads public and unchanged" do
    post "/api/v1/uploads", params: { file: jpeg_file }, headers: upload_headers

    expect(response).to have_http_status(:created)
    url = response.parsed_body["url"]
    expect(url).to start_with("http://www.example.com/uploads/")
    expect(File).to exist(Rails.root.join("public", "uploads", File.basename(url)))
  end

  it "normalizes an image extension from its content type as well" do
    post "/api/v1/uploads", params: { file: upload("image/jpeg", "photo.JPEG") }, headers: upload_headers

    expect(response.parsed_body["url"]).to end_with(".jpg")
  end

  it "requires authentication" do
    post "/api/v1/uploads", params: { file: pdf_file, kind: "document" }

    expect(response).to have_http_status(:unauthorized)
  end
end
