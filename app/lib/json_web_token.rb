# Thin wrapper around the jwt gem used to mint and verify access tokens.
# The signing key comes from HUMANA_JWT_SECRET, falling back to the app's
# secret_key_base so it works out of the box in development.
module JsonWebToken
  ALGORITHM = "HS256".freeze
  DEFAULT_TTL = 7.days

  module_function

  def secret
    ENV["HUMANA_JWT_SECRET"].presence || Rails.application.secret_key_base
  end

  def encode(payload, ttl: DEFAULT_TTL)
    claims = payload.merge(exp: ttl.from_now.to_i, iat: Time.current.to_i)
    JWT.encode(claims, secret, ALGORITHM)
  end

  # Returns the decoded payload as a HashWithIndifferentAccess, or nil if the
  # token is missing, malformed or expired.
  def decode(token)
    return nil if token.blank?

    payload, = JWT.decode(token, secret, true, algorithm: ALGORITHM)
    ActiveSupport::HashWithIndifferentAccess.new(payload)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
