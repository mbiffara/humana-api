Rails.application.routes.draw do
  # Health check for load balancers / uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Authentication
      post   "auth/login",  to: "sessions#create"
      get    "auth/me",     to: "sessions#show"
      delete "auth/logout", to: "sessions#destroy"

      # Discovery
      resources :experiences, only: %i[index show]
      get "coverage", to: "coverage#index"

      # Agency workspace
      resources :clients
      resources :bookings, only: %i[index show create update]
    end
  end

  # Friendly root for humans hitting the API host directly.
  root to: ->(_env) { [200, { "Content-Type" => "application/json" }, [{ service: "humana-api", status: "ok" }.to_json]] }
end
