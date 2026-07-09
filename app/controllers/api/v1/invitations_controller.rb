# Public invitation acceptance endpoints — no authentication required.
# Users arrive here via the magic link sent by email.
module Api
  module V1
    class InvitationsController < BaseController
      skip_before_action :authenticate_user!
      before_action :set_invitation

      # GET /api/v1/invitations/:token
      # Validates the invitation token and returns its details.
      def show
        if @invitation.accepted?
          render json: { error: "Invitation already accepted" }, status: :conflict
          return
        end

        if @invitation.expired?
          render json: { error: "Invitation has expired" }, status: :gone
          return
        end

        render json: {
          invitation: {
            email: @invitation.email,
            role: @invitation.role,
            organization: ApiSerializers.organization(@invitation.organization),
            expires_at: @invitation.expires_at
          }
        }
      end

      # POST /api/v1/invitations/:token/accept
      # Creates the user account, marks the invitation as accepted, and returns a JWT.
      def accept
        if @invitation.accepted?
          render json: { error: "Invitation already accepted" }, status: :conflict
          return
        end

        if @invitation.expired?
          render json: { error: "Invitation has expired" }, status: :gone
          return
        end

        user_params = params.require(:user).permit(:name, :password, :password_confirmation, :locale)

        # Update existing pending user (created at invite time) or create new one
        user = User.find_by(email: @invitation.email, organization: @invitation.organization)
        if user
          user.assign_attributes(
            name: user_params[:name],
            password: user_params[:password],
            password_confirmation: user_params[:password_confirmation],
            locale: user_params[:locale] || "en",
            status: "active"
          )
        else
          user = User.new(
            email: @invitation.email,
            name: user_params[:name],
            password: user_params[:password],
            password_confirmation: user_params[:password_confirmation],
            locale: user_params[:locale] || "en",
            role: @invitation.role,
            status: "active",
            organization: @invitation.organization
          )
        end

        unless user.save
          render json: { error: "Validation failed", details: user.errors.full_messages },
                 status: :unprocessable_entity
          return
        end

        @invitation.update!(accepted_at: Time.current)

        token = JsonWebToken.encode({ sub: user.id, org: user.organization_id })

        render json: {
          token: token,
          user: ApiSerializers.user(user).merge(status: user.status)
        }, status: :created
      end

      private

      def set_invitation
        @invitation = Invitation.find_by!(token: params[:token])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Invitation not found" }, status: :not_found
      end
    end
  end
end
