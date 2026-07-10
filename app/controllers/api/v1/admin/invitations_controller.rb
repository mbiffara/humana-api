# Lists and manages invitations from the admin dashboard.
module Api
  module V1
    module Admin
      class InvitationsController < BaseController
        def index
          scope = Invitation.includes(:organization, :invited_by)

          case params[:status]
          when "pending"
            scope = scope.pending
          when "expired"
            scope = scope.expired
          when "accepted"
            scope = scope.where.not(accepted_at: nil)
          end

          scope = scope.order(created_at: :desc)
          invitations = paginate(scope)

          render json: {
            invitations: invitations.map { |inv| serialize_invitation(inv) },
            meta: meta_for(scope),
          }
        end

        def destroy
          invitation = Invitation.find(params[:id])
          invitation.destroy!
          head :no_content
        end

        # POST /api/v1/admin/invitations/:id/resend
        def resend
          invitation = Invitation.find(params[:id])

          if invitation.accepted?
            return render_unprocessable("Invitation was already accepted.")
          end

          # Reset expiry
          invitation.update!(expires_at: 7.days.from_now)

          begin
            InvitationMailer.invite(invitation).deliver_now
          rescue StandardError => e
            Rails.logger.warn("[InvitationMailer] Resend delivery failed: #{e.message}")
            Rails.logger.info("[InvitationMailer] Magic link for #{invitation.email}: #{invitation.magic_link}")
          end

          render json: { invitation: serialize_invitation(invitation) }
        end

        private

        def serialize_invitation(inv)
          {
            id: inv.id,
            email: inv.email,
            role: inv.role,
            organization: {
              id: inv.organization.id,
              name: inv.organization.name,
              kind: inv.organization.kind,
              city: inv.organization.city,
              country: inv.organization.country,
            },
            invited_by: inv.invited_by&.name || inv.invited_by&.email,
            accepted_at: inv.accepted_at,
            expires_at: inv.expires_at&.iso8601,
            created_at: inv.created_at.iso8601,
            expired: inv.expired? && !inv.accepted?,
          }
        end
      end
    end
  end
end
