module Api
  module V1
    class UploadsController < BaseController
      ALLOWED_TYPES = %w[image/jpeg image/png image/webp].freeze
      # Paperwork (a deed, a power of attorney, a commercial registration)
      # usually arrives as a PDF, but a photo of the page counts too.
      DOCUMENT_TYPES = %w[application/pdf image/jpeg image/png image/webp].freeze
      # The extension comes from the content type we just validated, never
      # from the name the client chose — that name is attacker-controlled.
      EXTENSIONS = {
        "application/pdf" => "pdf",
        "image/jpeg" => "jpg",
        "image/png" => "png",
        "image/webp" => "webp"
      }.freeze
      MAX_SIZE = 10 * 1024 * 1024 # 10 MB

      # POST /api/v1/uploads
      # Content-Type: multipart/form-data
      # Body: file=<binary>, kind=document (optional)
      # Returns: { url: "<public url>" } for images,
      #          { url: "<host>/api/v1/documents/<name>" } for documents.
      def create
        file = params[:file]
        document = params[:kind] == "document"

        unless file.respond_to?(:original_filename)
          return render json: { error: "No file provided" }, status: :unprocessable_entity
        end

        allowed = document ? DOCUMENT_TYPES : ALLOWED_TYPES
        unless allowed.include?(file.content_type)
          message = document ? "Invalid file type. Allowed: PDF, JPEG, PNG, WebP" : "Invalid file type. Allowed: JPEG, PNG, WebP"
          return render json: { error: message }, status: :unprocessable_entity
        end

        if file.size > MAX_SIZE
          return render json: { error: "File too large. Maximum: 10 MB" }, status: :unprocessable_entity
        end

        name = "#{SecureRandom.uuid}.#{EXTENSIONS.fetch(file.content_type)}"

        if document
          store_document(file, name)
          # Verification paperwork is private: it never gets a readable URL of
          # its own, only this handle, which Api::V1::DocumentsController turns
          # into a short-lived signed link for whoever may see it.
          render json: { url: "#{request.base_url}/api/v1/documents/#{name}" }, status: :created
        else
          key = "uploads/#{name}"
          url = s3_configured? ? upload_to_s3(file, key) : upload_to_local(file, key)
          render json: { url: url }, status: :created
        end
      end

      private

      def s3_configured?
        ENV["AWS_BUCKET"].present?
      end

      # Out of the public bucket and out of public/ — a deed is readable only
      # through a signed link, never by guessing a URL.
      def store_document(file, name)
        if s3_configured?
          upload_to_s3(file, "documents/#{name}", acl: "private")
        else
          path = Rails.root.join("storage", "documents", name)
          FileUtils.mkdir_p(path.dirname)
          File.open(path, "wb") { |f| f.write(file.read) }
        end
      end

      def upload_to_s3(file, key, acl: nil)
        require "aws-sdk-s3"

        bucket = ENV.fetch("AWS_BUCKET")
        region = ENV.fetch("AWS_REGION", "us-east-1")

        client = Aws::S3::Client.new(region: region)
        params = {
          bucket: bucket,
          key: key,
          body: file.read,
          content_type: file.content_type
        }
        params[:acl] = acl if acl
        client.put_object(**params)

        "https://#{bucket}.s3.#{region}.amazonaws.com/#{key}"
      end

      # Mirrors the S3 key under public/ so the returned URL is the same either
      # way. Images only — documents never land here.
      def upload_to_local(file, key)
        path = Rails.root.join("public", key)
        FileUtils.mkdir_p(path.dirname)
        File.open(path, "wb") { |f| f.write(file.read) }
        "#{request.protocol}#{request.host_with_port}/#{key}"
      end
    end
  end
end
