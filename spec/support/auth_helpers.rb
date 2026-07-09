# Helper methods for authenticating requests in tests.
module AuthHelpers
  def auth_headers(user)
    token = JsonWebToken.encode({ sub: user.id, org: user.organization_id })
    { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
