# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
rails server -p 4000          # Dev server
rails db:migrate               # Run migrations
rails db:seed                  # Seed data (idempotent)
rails db:reset                 # Drop + create + migrate + seed
bundle exec rspec              # Run tests
bundle exec rspec spec/path    # Run single test file
bundle exec brakeman           # Security analysis
bundle exec bundler-audit      # Gem vulnerability scan
rails console                  # Interactive console
```

## Tech Stack

- **Rails 8.0** (API-only mode) + **Ruby 3.3**
- **PostgreSQL** — database
- **bcrypt** — `has_secure_password` (min 8 chars)
- **jwt** (~> 2.8) — HS256 tokens, 7-day TTL
- **rack-cors** — CORS for Next.js frontend
- **resend** (~> 0.17) — Transactional email (invitations)
- **dotenv-rails** — `.env` file loading (dev/test)
- **puma** — web server
- **rspec-rails** + **factory_bot_rails** — Testing

## Architecture

### Auth

JWT-based stateless auth. Token payload: `{ sub: user.id, org: user.organization_id, exp: 7.days, iat: now }`.

Signing key: `ENV["HUMANA_JWT_SECRET"]` or fallback to `Rails.application.secret_key_base`.

```ruby
# app/lib/json_web_token.rb
JsonWebToken.encode(payload)   # → token string
JsonWebToken.decode(token)     # → HashWithIndifferentAccess or nil
```

### Controller Hierarchy

```
ApplicationController
├── authenticate_user!         # Requires valid JWT
├── current_user               # From JWT sub claim
├── require_admin!             # platform_admin? check
├── require_agency!            # organization.agency? check
├── require_hotel!             # organization.hotel? check
├── require_office!            # organization.office? check
├── render_unauthorized/forbidden/not_found/unprocessable/bad_request
│
└── Api::V1::BaseController    # before_action :authenticate_user!
    ├── current_organization   # current_user.organization
    ├── paginate(scope)        # Offset-limit pagination
    ├── meta_for(scope)        # { page, per_page, total, total_pages }
    │
    ├── SessionsController     # POST login, GET me, DELETE logout
    ├── ExperiencesController  # GET index/show (authenticated)
    ├── ClientsController      # CRUD (agency-only)
    ├── BookingsController     # CRUD (agency-only)
    ├── CoverageController     # GET map markers
    ├── InvitationsController  # GET show, POST accept (public, no auth)
    │
    ├── Api::V1::PublicController  # skip authenticate_user!
    │   ├── Public::HotelsController
    │   └── Public::ExperiencesController
    │
    ├── Api::V1::Admin::BaseController  # require_admin!
    │   ├── StatsController
    │   ├── OrganizationsController
    │   ├── UsersController            # + invite/approve/reject/suspend/reactivate
    │   ├── InvitationsController      # + resend
    │   ├── CountriesController
    │   ├── PlatformSettingsController
    │   ├── SubscriptionPlansController
    │   ├── SubscriptionsController
    │   └── RetreatsController         # + approve/reject/close
    │
    ├── Api::V1::Hotel::BaseController  # require_hotel!
    │   ├── ProfilesController         # + submit_for_review
    │   ├── RoomTypesController
    │   ├── AmenitiesController        # + batch
    │   ├── ImagesController           # + batch
    │   └── RetreatsController         # + nested: days, activities, facilitators,
    │       ├── RetreatDaysController        inclusions, pricings, images
    │       ├── RetreatActivitiesController
    │       ├── RetreatFacilitatorsController
    │       ├── RetreatInclusionsController
    │       ├── RetreatPricingsController
    │       └── RetreatImagesController
    │
    ├── Api::V1::Agency::BaseController  # require_agency!
    │   └── ProfilesController
    │
    └── Api::V1::Office::BaseController  # require_office!
        └── ProfilesController
```

### Serializers

Plain Ruby module at `app/serializers/api_serializers.rb`. No gem dependency.

```ruby
ApiSerializers.user(user)
ApiSerializers.organization(org)
ApiSerializers.hotel(hotel)
ApiSerializers.experience(exp, include_commission: true)
ApiSerializers.client(client)
ApiSerializers.booking(booking, include_experience: true)
```

### Database Schema (22 tables)

See root CLAUDE.md for the full schema listing. Key tables:

```
organizations, users, hotels, experiences, clients, bookings,
retreats, retreat_days, retreat_activities, retreat_facilitators,
retreat_inclusions, retreat_pricings, retreat_images,
room_types, room_images, hotel_amenities, hotel_images,
invitations, countries, platform_settings,
subscription_plans, subscriptions, stripe_connect_accounts
```

### Key Indexes
- `users`: unique on `lower(email)`, index on `organization_id`, `status`
- `experiences`: unique on `slug`, indexes on `hotel_id`, `kind`, `status`, `country_code`
- `bookings`: unique on `reference`, indexes on `organization_id`, `experience_id`, `client_id`, `status`
- `retreats`: unique on `slug`, indexes on `hotel_id+status`, `status`, `country_code`, `retreat_type`, `featured`
- `invitations`: unique on `token`, index on `email`
- `countries`: unique on `code`

### Routes

```ruby
namespace :api do
  namespace :v1 do
    # Auth
    post   "auth/login",  to: "sessions#create"
    get    "auth/me",     to: "sessions#show"
    delete "auth/logout", to: "sessions#destroy"

    # Public
    namespace :public do
      resources :hotels, only: %i[index show]
      resources :experiences, only: %i[index show]
    end
    resources :invitations, only: [:show], param: :token do
      member { post :accept }
    end

    # Admin
    namespace :admin do
      get "stats", to: "stats#index"
      resources :invitations, only: %i[index destroy] do
        member { post :resend }
      end
      resources :organizations
      resources :users, only: %i[index show destroy] do
        collection { post :invite }
        member { post :approve; post :reject; post :suspend; post :reactivate }
      end
      resources :countries
      resource :platform_settings, only: %i[show update]
      resources :subscription_plans
      resources :subscriptions, only: %i[index show]
      resources :retreats, only: %i[index show] do
        member { post :approve; post :reject; post :close }
      end
    end

    # Hotel
    namespace :hotel do
      resource :profile, only: %i[show update] do
        post :submit_for_review, on: :member
      end
      resources :room_types
      resources :amenities, only: [:index] { collection { post :batch } }
      resources :images, only: %i[index create destroy] { collection { post :batch } }
      resources :retreats do
        member { post :submit_for_review }
        resources :days, :facilitators, :inclusions, :pricings, :images  # nested
      end
    end

    # Agency & Office
    namespace(:agency) { resource :profile, only: %i[show update] }
    namespace(:office) { resource :profile, only: %i[show update] }

    # Authenticated discovery
    resources :experiences, only: %i[index show]
    get "coverage", to: "coverage#index"
    resources :clients
    resources :bookings, only: %i[index show create update]
  end
end
```

### CORS

Allowed origins: `ENV["HUMANA_WEB_ORIGINS"]` or defaults to `localhost:3000,127.0.0.1:3000`.

### Seeds

Idempotent (`find_or_create_by`). Creates:
- Platform admin org "HUMANA Global" + user `admin@humana.global` / `humana1234`
- Agency "Viajes Éter" + user `agent@viajeseter.com` / `humana1234`
- 4 hotel orgs with 1 experience each (Spain, Mexico, Singapore, Bali)
- 2 sample clients + 1 confirmed booking

## Conventions

- All money stored as `_cents` (integer) — divide by 100 for display
- Commission rates stored as decimal 0–1 (0.16 = 16%)
- Slugs auto-generated from title on `Experience` and `Retreat` creation
- Booking references auto-generated as `HMN-XXXXXX` (6 random uppercase alphanumeric)
- Dates stored as `date` type (not datetime) for experiences/bookings/retreats
- Pagination: `?page=1&per_page=25` (max 100)
- Invitation tokens are `SecureRandom.urlsafe_base64(32)`, expire in 7 days

## Adding New Role-Scoped Namespaces

When creating new controllers for hotel/agency/office/admin scopes:

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    namespace :admin do
      resources :organizations
    end
  end
end

# app/controllers/api/v1/admin/base_controller.rb
module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        before_action :require_admin!
      end
    end
  end
end

# app/controllers/api/v1/admin/organizations_controller.rb
module Api
  module V1
    module Admin
      class OrganizationsController < BaseController
        # ...
      end
    end
  end
end
```

Repeat pattern for `hotel`, `agency`, `office` namespaces with their respective `require_X!` guards.
