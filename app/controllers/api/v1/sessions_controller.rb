module Api
  module V1
    # Email + password login that returns a JWT, plus the authenticated user.
    class SessionsController < BaseController
      skip_before_action :authenticate_user!, only: :create

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

      # DELETE /api/v1/auth/logout
      # Tokens are stateless; the client simply discards it.
      def destroy
        head :no_content
      end

      private

      def login_params
        params.require(:auth).permit(:email, :password)
      end
    end
  end
end
