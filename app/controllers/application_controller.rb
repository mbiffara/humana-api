class ApplicationController < ActionController::API
  # Standard JSON error envelope for the whole API.
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def authenticate_user!
    render_unauthorized and return unless current_user
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: token_payload&.dig(:sub))
  end

  def token_payload
    @token_payload ||= JsonWebToken.decode(bearer_token)
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    header.start_with?("Bearer ") ? header.split(" ", 2).last : nil
  end

  def require_admin!
    render_forbidden and return unless current_user&.platform_admin?
  end

  def require_agency!
    render_forbidden and return unless current_user&.agency?
  end

  def require_active_user!
    return unless current_user
    return if current_user.status.in?(%w[active pending]) || current_user.platform_admin?

    render json: { error: "account_suspended" }, status: :forbidden
  end

  # --- Renderers ---------------------------------------------------------

  def render_error(message, status, details: nil)
    body = { error: message }
    body[:details] = details if details
    render json: body, status: status
  end

  def render_unauthorized
    render_error("Authentication required", :unauthorized)
  end

  def render_forbidden
    render_error("You don't have access to this resource", :forbidden)
  end

  def render_not_found(exception = nil)
    render_error(exception&.message || "Resource not found", :not_found)
  end

  def render_unprocessable(arg)
    case arg
    when ActiveRecord::RecordInvalid
      render_error("Validation failed", :unprocessable_entity,
                   details: arg.record.errors.full_messages)
    when String
      render_error(arg, :unprocessable_entity)
    when Array
      render_error("Validation failed", :unprocessable_entity, details: arg)
    else
      render_error("Validation failed", :unprocessable_entity)
    end
  end

  def render_bad_request(exception)
    render_error(exception.message, :bad_request)
  end
end
