module Api
  module V1
    class UploadsController < BaseController
      ALLOWED_TYPES = %w[image/jpeg image/png image/webp].freeze
      MAX_SIZE = 10 * 1024 * 1024 # 10 MB

      # POST /api/v1/uploads
      # Content-Type: multipart/form-data
      # Body: file=<binary>
      # Returns: { url: "<s3 or local url>" }
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
        filename = "uploads/#{SecureRandom.uuid}#{ext}"

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

      def upload_to_local(file, key)
        local_filename = File.basename(key)
        upload_dir = Rails.root.join("public", "uploads")
        FileUtils.mkdir_p(upload_dir)
        File.open(upload_dir.join(local_filename), "wb") { |f| f.write(file.read) }
        "#{request.protocol}#{request.host_with_port}/uploads/#{local_filename}"
      end
    end
  end
end
