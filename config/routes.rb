Rails.application.routes.draw do
  # Health check for load balancers / uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Authentication
      post   "auth/login",  to: "sessions#create"
      get    "auth/me",     to: "sessions#show"
      patch  "auth/me",     to: "sessions#update"
      delete "auth/logout", to: "sessions#destroy"

      # Public discovery (no authentication) — for marketing / unauthenticated surfaces
      namespace :public do
        resources :hotels, only: %i[index show]
        resources :experiences, only: %i[index show]
      end

      # Invitation acceptance (no authentication)
      resources :invitations, only: [:show], param: :token do
        member { post :accept }
      end

      # Admin console
      namespace :admin do
        get "stats", to: "stats#index"
        resources :invitations, only: %i[index destroy] do
          member { post :resend }
        end
        resources :organizations
        resources :hotels, only: [:show]
        resources :users, only: %i[index show destroy] do
          collection { post :invite }
          member do
            post :approve
            post :reject
            post :send_feedback
            post :suspend
            post :reactivate
          end
        end
        resources :countries
        resource :platform_settings, only: %i[show update]
        resources :subscription_plans
        resources :subscriptions, only: %i[index show]
        resources :retreats, only: %i[index show] do
          member do
            post :approve
            post :reject
            post :close
          end
        end
      end

      # Agency workspace
      namespace :agency do
        resource :profile, only: %i[show update]
      end

      # Office workspace
      namespace :office do
        resource :profile, only: %i[show update]
      end

      # Hotel workspace
      namespace :hotel do
        resource :profile, only: %i[show update] do
          post :submit_for_review, on: :member
        end
        resources :room_types
        resources :rooms, only: %i[index create update destroy]
        resources :availability_blocks, only: %i[index create destroy]
        get "calendar", to: "calendar#index"
        resources :amenities, only: %i[index] do
          collection { post :batch }
        end
        resources :images, only: %i[index create destroy], controller: "images" do
          collection { post :batch }
        end
        resources :retreats do
          member do
            post :submit_for_review
            post :publish
          end
          resources :days, controller: "retreat_days", except: [:show] do
            resources :activities, controller: "retreat_activities", except: [:show]
          end
          resources :facilitators, controller: "retreat_facilitators", except: [:show]
          resources :inclusions, controller: "retreat_inclusions", except: [:show]
          resources :pricings, controller: "retreat_pricings", except: [:show]
          resources :images, controller: "retreat_images", except: [:show] do
            collection { post :batch }
          end
        end
      end

      # File uploads (any authenticated user)
      resources :uploads, only: [:create]

      # Discovery
      resources :experiences, only: %i[index show]
      get "coverage", to: "coverage#index"

      # Agency workspace
      resources :clients
      resources :bookings, only: %i[index show create update]
    end
  end

  # Friendly root for humans hitting the API host directly.
  root to: "root#show"
end
