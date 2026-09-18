module Api
  module V1
    # Verification paperwork (a deed, a power of attorney, a tax certificate)
    # is private. The upload endpoint stores it outside the public tree and
    # hands back a handle; this controller is the only way to read it back.
    #
    # `link` authenticates the caller and mints a short-lived signature.
    # `show` takes no JWT — the browser follows the link from an <img> or a new
    # tab, where no Authorization header travels — so the signature is the
    # whole proof, and it expires in minutes.
    class DocumentsController < ApplicationController
      # A stored document is always a UUID plus one of four extensions.
      # Anything else is not ours, and refusing it here is what keeps a name
      # from params out of a filesystem path.
      NAME_PATTERN = /[0-9a-f-]{36}\.(?:pdf|jpg|png|webp)/
      NAME_FORMAT = /\A#{NAME_PATTERN}\z/
      # The handle is identified by its path alone. Host and scheme drift —
      # http to https, a proxy that forgets X-Forwarded-Proto, a new domain —
      # and every URL stored before the drift would otherwise stop resolving.
      PATH_FORMAT = %r{/api/v1/documents/(#{NAME_PATTERN})\z}
      CONTENT_TYPES = {
        "pdf" => "application/pdf",
        "jpg" => "image/jpeg",
        "png" => "image/png",
        "webp" => "image/webp"
      }.freeze
      LINK_TTL = 10.minutes
      S3_LINK_TTL = 5.minutes

      before_action :authenticate_user!, only: :link
      before_action :require_active_user!, only: :link

      # POST /api/v1/documents/link
      # Body: { url: "<host>/api/v1/documents/<name>" }
      # Returns: { url: "<same>?token=<signature>" }
      def link
        name = document_name(params[:url])
        return render_error("Document not found", :not_found) if name.nil?
        return render_forbidden("You don't have access to this document") unless may_read?(name)

        token = verifier.generate({ name: name }, expires_in: LINK_TTL)
        render json: { url: "#{request.base_url}/api/v1/documents/#{name}?token=#{CGI.escape(token)}" }
      end

      # GET /api/v1/documents/:name?token=<signature>
      def show
        match = NAME_FORMAT.match(params[:name].to_s)
        return render_error("Document not found", :not_found) if match.nil?

        name = match[0]
        return render_forbidden("This link is no longer valid") unless token_name(params[:token]) == name

        response.headers["Cache-Control"] = "private, no-store"

        if s3_configured?
          redirect_to presigned_url(name), allow_other_host: true
        else
          serve_local(name)
        end
      end

      private

      def verifier
        Rails.application.message_verifier(:documents)
      end

      # Only the path decides, so a handle keeps resolving after the host or
      # the scheme changes. The name itself is still exact.
      def document_name(url)
        PATH_FORMAT.match(URI.parse(url.to_s).path.to_s)&.captures&.first
      rescue URI::InvalidURIError
        nil
      end

      # Ownership is a comparison between names, not between URLs, for the
      # same reason: the organization may have stored its handle under a host
      # this request no longer speaks.
      def may_read?(name)
        return true if current_user&.platform_admin?

        document_name(current_user&.organization&.ownership_document_url) == name
      end

      def token_name(token)
        payload = verifier.verified(token.to_s)
        return nil unless payload.is_a?(Hash)

        payload.with_indifferent_access[:name]
      end

      def s3_configured?
        ENV["AWS_BUCKET"].present?
      end

      def serve_local(name)
        path = File.join(document_root, name)
        return render_error("Document not found", :not_found) unless File.exist?(path)

        send_file path, type: CONTENT_TYPES.fetch(name.split(".").last), disposition: "inline"
      end

      def document_root
        Rails.root.join("storage", "documents").to_s
      end

      def presigned_url(name)
        require "aws-sdk-s3"

        Aws::S3::Presigner.new(client: Aws::S3::Client.new(region: ENV.fetch("AWS_REGION", "us-east-1")))
                          .presigned_url(:get_object,
                                         bucket: ENV.fetch("AWS_BUCKET"),
                                         key: "documents/#{name}",
                                         expires_in: S3_LINK_TTL.to_i)
      end
    end
  end
end
