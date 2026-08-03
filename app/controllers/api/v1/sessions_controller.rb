module Api
  module V1
    # Email + password login that returns a JWT, plus the authenticated user.
    class SessionsController < BaseController
      skip_before_action :authenticate_user!, only: %i[create request_password_reset reset_password]
      skip_before_action :require_active_user!, only: %i[create show request_password_reset reset_password]

      # POST /api/v1/auth/login
      def create
        user = User.find_by("lower(email) = ?", login_params[:email].to_s.strip.downcase)

        if user&.authenticate(login_params[:password])
          user.touch_login!
          token = JsonWebToken.encode({ sub: user.id, org: user.organization_id })
          render json: { token: token, user: ApiSerializers.user(user) }, status: :created
        else
          render_error("Invalid email or password", :unauthorized)
        end
      end

      # GET /api/v1/auth/me
      def show
        render json: { user: ApiSerializers.user(current_user) }
      end

      # PATCH /api/v1/auth/me
      def update
        current_user.update!(profile_params)
        render json: { user: ApiSerializers.user(current_user) }
      end

      # PATCH /api/v1/auth/password
      def change_password
        unless current_user.authenticate(password_params[:current_password].to_s)
          return render_error("Current password is incorrect", :unprocessable_entity)
        end

        if current_user.update(password: password_params[:new_password])
          render json: { message: "Password updated successfully" }
        else
          render_error(current_user.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      # POST /api/v1/auth/deactivate
      def deactivate
        current_user.update!(status: "suspended")
        head :no_content
      end

      # DELETE /api/v1/auth/account
      def delete_account
        org = current_user.organization
        current_user.destroy!
        org.destroy! if org.users.count.zero?
        head :no_content
      end

      # POST /api/v1/auth/request_password_reset (no auth)
      # Always returns 200 to avoid leaking email existence.
      def request_password_reset
        email = params.dig(:auth, :email).to_s.strip.downcase
        user = User.find_by("lower(email) = ?", email)

        if user
          user.update!(
            password_reset_token: SecureRandom.urlsafe_base64(32),
            password_reset_sent_at: Time.current,
          )
          PasswordResetMailer.reset(user).deliver_later
        end

        render json: { message: "If that email exists, a reset link has been sent." }
      end

      # POST /api/v1/auth/reset_password (no auth)
      def reset_password
        token = params.dig(:auth, :token).to_s
        password = params.dig(:auth, :password).to_s

        user = User.find_by(password_reset_token: token)

        if user.nil? || user.password_reset_sent_at.nil? || user.password_reset_sent_at < 1.hour.ago
          return render_error("Invalid or expired reset token", :unprocessable_entity)
        end

        if password.length < 8
          return render_error("Password must be at least 8 characters", :unprocessable_entity)
        end

        user.update!(
          password: password,
          password_reset_token: nil,
          password_reset_sent_at: nil,
        )

        user.touch_login!
        jwt = JsonWebToken.encode({ sub: user.id, org: user.organization_id })
        render json: { token: jwt, user: ApiSerializers.user(user) }
      end

      # DELETE /api/v1/auth/logout
      # Tokens are stateless; the client simply discards it.
      def destroy
        head :no_content
      end

      private

      def login_params
        params.require(:auth).permit(:email, :password)
      end

      def profile_params
        params.require(:user).permit(:name)
      end

      def password_params
        params.require(:auth).permit(:current_password, :new_password)
      end
    end
  end
end
