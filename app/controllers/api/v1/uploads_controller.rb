# Simple file upload endpoint — saves to public/uploads/ and returns a URL.
# Served as static assets by Puma/Rails. In production, swap for S3/CDN.
module Api
  module V1
    class UploadsController < BaseController
      ALLOWED_TYPES = %w[image/jpeg image/png image/webp].freeze
      MAX_SIZE = 10 * 1024 * 1024 # 10 MB

      # POST /api/v1/uploads
      # Content-Type: multipart/form-data
      # Body: file=<binary>
      # Returns: { url: "http://localhost:4000/uploads/<uuid>.ext" }
      def create
        file = params[:file]

        unless file.respond_to?(:original_filename)
          return render json: { error: "No file provided" }, status: :unprocessable_entity
        end

        unless ALLOWED_TYPES.include?(file.content_type)
          return render json: { error: "Invalid file type. Allowed: JPEG, PNG, WebP" }, status: :unprocessable_entity
        end

        if file.size > MAX_SIZE
          return render json: { error: "File too large. Maximum: 10 MB" }, status: :unprocessable_entity
        end

        ext = File.extname(file.original_filename).downcase.presence || ".jpg"
        filename = "#{SecureRandom.uuid}#{ext}"

        upload_dir = Rails.root.join("public", "uploads")
        FileUtils.mkdir_p(upload_dir)

        File.open(upload_dir.join(filename), "wb") { |f| f.write(file.read) }

        url = "#{request.protocol}#{request.host_with_port}/uploads/#{filename}"
        render json: { url: url }, status: :created
      end
    end
  end
end
