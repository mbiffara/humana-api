module Api
  module V1
    class UploadsController < BaseController
      ALLOWED_TYPES = %w[image/jpeg image/png image/webp].freeze
      # Paperwork (a deed, a power of attorney, a commercial registration)
      # usually arrives as a PDF, but a photo of the page counts too.
      DOCUMENT_TYPES = %w[application/pdf image/jpeg image/png image/webp].freeze
      MAX_SIZE = 10 * 1024 * 1024 # 10 MB

      # POST /api/v1/uploads
      # Content-Type: multipart/form-data
      # Body: file=<binary>, kind=document (optional)
      # Returns: { url: "<s3 or local url>" }
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

        ext = File.extname(file.original_filename).downcase.presence || (document ? ".pdf" : ".jpg")
        filename = "#{document ? 'documents' : 'uploads'}/#{SecureRandom.uuid}#{ext}"

        if s3_configured?
          url = upload_to_s3(file, filename)
        else
          url = upload_to_local(file, filename)
        end

        render json: { url: url }, status: :created
      end

      private

      def s3_configured?
        ENV["AWS_BUCKET"].present?
      end

      def upload_to_s3(file, key)
        require "aws-sdk-s3"

        bucket = ENV.fetch("AWS_BUCKET")
        region = ENV.fetch("AWS_REGION", "us-east-1")

        client = Aws::S3::Client.new(region: region)
        client.put_object(
          bucket: bucket,
          key: key,
          body: file.read,
          content_type: file.content_type
        )

        "https://#{bucket}.s3.#{region}.amazonaws.com/#{key}"
      end

      # Mirrors the S3 key under public/ so the returned URL carries the same
      # prefix either way — images under uploads/, paperwork under documents/.
      def upload_to_local(file, key)
        path = Rails.root.join("public", key)
        FileUtils.mkdir_p(path.dirname)
        File.open(path, "wb") { |f| f.write(file.read) }
        "#{request.protocol}#{request.host_with_port}/#{key}"
      end
    end
  end
end
