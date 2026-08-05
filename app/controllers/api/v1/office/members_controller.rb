module Api
  module V1
    module Office
      class MembersController < BaseController
        # GET /api/v1/office/members
        def index
          members = current_organization.users.order(:name)
          pending_invitations = current_organization.invitations
            .where(accepted_at: nil)
            .where("expires_at > ?", Time.current)
            .order(created_at: :desc)

          render json: {
            members: members.map { |u| ApiSerializers.user(u) },
            pending_invitations: pending_invitations.map { |inv| serialize_invitation(inv) }
          }
        end

        # POST /api/v1/office/members/invite
        def invite
          email = params[:email].to_s.strip.downcase
          role = params[:role] || "member"

          return render json: { error: "Email is required" }, status: :unprocessable_entity if email.blank?

          existing = User.find_by("LOWER(email) = ?", email)
          if existing && existing.status != "pending"
            return render json: { error: "already_registered", message: "This email is already registered." }, status: :unprocessable_entity
          end

          existing_inv = Invitation.pending.where("LOWER(email) = ?", email).first
          if existing_inv
            return render json: { error: "already_invited", message: "An invitation has already been sent." }, status: :unprocessable_entity
          end

          invitation = Invitation.create!(
            email: email,
            role: role,
            organization: current_organization,
            invited_by: current_user
          )

          # Create pending user record
          temp_password = SecureRandom.hex(16)
          User.find_or_create_by!(email: email) do |u|
            u.name = email.split("@").first.titleize
            u.password = temp_password
            u.password_confirmation = temp_password
            u.role = role
            u.organization = current_organization
            u.status = "active" # Office members are auto-approved (staff)
          end

          begin
            InvitationMailer.invite(invitation).deliver_now
          rescue StandardError => e
            Rails.logger.warn("[InvitationMailer] Email delivery failed: #{e.message}")
          end

          render json: { invitation: serialize_invitation(invitation) }, status: :created
        end

        private

        def serialize_invitation(inv)
          {
            id: inv.id,
            email: inv.email,
            role: inv.role,
            organization: ApiSerializers.organization(inv.organization),
            expires_at: inv.expires_at,
            invited_by: inv.invited_by&.name,
            created_at: inv.created_at
          }
        end
      end
    end
  end
end
