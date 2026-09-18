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
      # A stored document is always a UUID plus one of four extensions, filed
      # under the id of the organization that uploaded it. Refusing anything
      # else here is what keeps a name from params out of a filesystem path.
      NAME_PATTERN = /[0-9a-f-]{36}\.(?:pdf|jpg|png|webp)/
      NAME_FORMAT = /\A#{NAME_PATTERN}\z/
      ORG_ID_FORMAT = /\A\d+\z/
      # The handle is identified by its path alone. Host and scheme drift —
      # http to https, a proxy that forgets X-Forwarded-Proto, a new domain —
      # and every URL stored before the drift would otherwise stop resolving.
      PATH_FORMAT = %r{/api/v1/documents/(\d+)/(#{NAME_PATTERN})\z}
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
      # Body: { url: "<host>/api/v1/documents/<org_id>/<name>" }
      # Returns: { url: "<same>?token=<signature>" }
      def link
        org_id, name = handle_parts(params[:url])
        return render_error("Document not found", :not_found) if name.nil?
        return render_forbidden("You don't have access to this document") unless may_read?(org_id)

        token = verifier.generate({ org_id: org_id, name: name }, expires_in: LINK_TTL)
        render json: {
          url: "#{request.base_url}/api/v1/documents/#{org_id}/#{name}?token=#{CGI.escape(token)}"
        }
      end

      # GET /api/v1/documents/:org_id/:name?token=<signature>
      def show
        org_id = params[:org_id].to_s
        name = NAME_FORMAT.match(params[:name].to_s)&.to_s
        return render_error("Document not found", :not_found) if name.nil? || !org_id.match?(ORG_ID_FORMAT)

        # The signature names the exact document. A token minted for one
        # organization cannot be pointed at another one's file.
        return render_forbidden("This link is no longer valid") unless signed_for?(org_id, name)

        response.headers["Cache-Control"] = "private, no-store"

        if s3_configured?
          redirect_to presigned_url(org_id, name), allow_other_host: true
        else
          serve_local(org_id, name)
        end
      end

      private

      def verifier
        Rails.application.message_verifier(:documents)
      end

      # Only the path decides, so a handle keeps resolving after the host or
      # the scheme changes.
      def handle_parts(url)
        PATH_FORMAT.match(URI.parse(url.to_s).path.to_s)&.captures
      rescue URI::InvalidURIError
        nil
      end

      # Ownership comes from where the document lives, not from a field the
      # hotel writes: `ownership_document_url` is hotel-supplied, so trusting
      # it would let anyone who guesses a UUID claim someone else's paperwork.
      #
      # And within the organization it is the owner's alone. A deed or a tax
      # certificate names people, so belonging to the property is not reason
      # enough to read it — only whoever signs for the property, or the
      # platform admin reviewing the submission.
      def may_read?(org_id)
        return true if current_user&.platform_admin?

        current_user&.owner? && org_id.to_i == current_user.organization_id
      end

      def signed_for?(org_id, name)
        payload = verifier.verified(params[:token].to_s)
        return false unless payload.is_a?(Hash)

        payload = payload.with_indifferent_access
        payload[:org_id].to_s == org_id && payload[:name] == name
      end

      def s3_configured?
        ENV["AWS_BUCKET"].present?
      end

      def serve_local(org_id, name)
        path = File.join(document_root, org_id, name)
        return render_error("Document not found", :not_found) unless File.exist?(path)

        send_file path, type: CONTENT_TYPES.fetch(name.split(".").last), disposition: "inline"
      end

      def document_root
        Rails.root.join("storage", "documents").to_s
      end

      def presigned_url(org_id, name)
        require "aws-sdk-s3"

        Aws::S3::Presigner.new(client: Aws::S3::Client.new(region: ENV.fetch("AWS_REGION", "us-east-1")))
                          .presigned_url(:get_object,
                                         bucket: ENV.fetch("AWS_BUCKET"),
                                         key: "documents/#{org_id}/#{name}",
                                         expires_in: S3_LINK_TTL.to_i)
      end
    end
  end
end
