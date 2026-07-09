# CLAUDE.md — HUMANA API (Backend)

This file provides guidance to Claude Code when working with the Rails API backend.

## Commands

```bash
rails server -p 4000          # Dev server
rails db:migrate               # Run migrations
rails db:seed                  # Seed data (idempotent)
rails db:reset                 # Drop + create + migrate + seed
bundle exec brakeman           # Security analysis
bundle exec bundler-audit      # Gem vulnerability scan
rails console                  # Interactive console
```

No test framework is configured yet.

## Tech Stack

- **Rails 8.0** (API-only mode) + **Ruby 3.3**
- **PostgreSQL** — database
- **bcrypt** — `has_secure_password` (min 8 chars)
- **jwt** (~> 2.8) — HS256 tokens, 7-day TTL
- **rack-cors** — CORS for Next.js frontend
- **puma** — web server

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
    │
    └── Api::V1::PublicController  # skip authenticate_user!
        ├── Public::HotelsController
        └── Public::ExperiencesController
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

### Database Schema (existing tables)

```
organizations: id, name, kind, status, city, country, country_code, contact_email, website
users:         id, organization_id, email, password_digest, name, role, locale, last_login_at
hotels:        id, organization_id, name, city, country, country_code, latitude, longitude, certified, wellness_standard, description
experiences:   id, hotel_id, slug, kind, title, description, location, country, country_code, starts_on, ends_on, price_cents, currency, commission_rate, capacity, image_url, status
clients:       id, organization_id, name, email, phone, notes
bookings:      id, organization_id, experience_id, client_id, reference, guests, starts_on, ends_on, status, amount_cents, currency, commission_cents, notes
```

### Key Indexes
- `users`: unique on `lower(email)`, index on `organization_id`
- `experiences`: unique on `slug`, indexes on `hotel_id`, `kind`, `status`, `country_code`
- `bookings`: unique on `reference`, indexes on `organization_id`, `experience_id`, `client_id`, `status`

### Routes

```ruby
namespace :api do
  namespace :v1 do
    post   "auth/login",  to: "sessions#create"
    get    "auth/me",     to: "sessions#show"
    delete "auth/logout", to: "sessions#destroy"

    namespace :public do
      resources :hotels, only: %i[index show]
      resources :experiences, only: %i[index show]
    end

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
- Slugs auto-generated from title on `Experience` creation
- Booking references auto-generated as `HMN-XXXXXX` (6 random uppercase alphanumeric)
- Dates stored as `date` type (not datetime) for experiences/bookings
- Pagination: `?page=1&per_page=25` (max 100)

## Adding New Role-Scoped Namespaces

When creating new controllers for hotel/agency/office/admin scopes:

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    namespace :admin do
      resources :organizations
      # ...
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
