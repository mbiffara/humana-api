class RootController < ApplicationController
  # Public landing for the API host: identifies the service and its version.
  # API_VERSION is supplied via the environment (see the ECS task definition).
  def show
    render json: {
      name: "humana-global-api",
      version: ENV.fetch("API_VERSION", "unknown")
    }
  end
end
