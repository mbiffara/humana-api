# HUMANA API

JSON API backend for the **humana-app** Next.js front-end (the sibling
`../humana-app` directory). HUMANA is a private, restricted-access B2B platform
connecting wellness hotels, tourism agencies and the HUMANA admin team.

- **Rails 8.0** · API-only · Ruby 3.3
- **PostgreSQL** (`@homebrew postgresql@14`)
- **JWT** bearer-token authentication (`jwt` gem) over **bcrypt** passwords
- **CORS** enabled for the Next.js dev server

## Getting started

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server -p 3001          # http://127.0.0.1:3001
```

Seed accounts (password `humana1234`):

| Email                    | Role  | Organization        |
|--------------------------|-------|---------------------|
| `agent@viajeseter.com`   | owner | Viajes Éter (agency)|
| `admin@humana.global`    | admin | HUMANA Global       |

## Configuration

All optional in development; set in production.

| Variable               | Purpose                                              | Default                                   |
|------------------------|------------------------------------------------------|-------------------------------------------|
| `HUMANA_JWT_SECRET`    | Signing key for JWTs                                  | `secret_key_base`                         |
| `HUMANA_WEB_ORIGINS`   | Comma-separated CORS allow-list                       | `http://localhost:3000,http://127.0.0.1:3000` |
| `DATABASE_URL`         | Postgres connection (overrides `config/database.yml`)| local socket as current OS user           |

## Authentication

```bash
# 1. Exchange credentials for a token
curl -X POST http://127.0.0.1:3001/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"auth":{"email":"agent@viajeseter.com","password":"humana1234"}}'
# => { "token": "<jwt>", "user": { ... } }

# 2. Send it on every authenticated request
curl http://127.0.0.1:3001/api/v1/auth/me -H 'Authorization: Bearer <jwt>'
```

## Endpoints (`/api/v1`)

| Method | Path                | Auth         | Description                                         |
|--------|---------------------|--------------|-----------------------------------------------------|
| POST   | `/auth/login`       | public       | Email + password → JWT + user                       |
| GET    | `/auth/me`          | any user     | Current user + organization                         |
| DELETE | `/auth/logout`      | any user     | No-op (token is stateless; client discards it)      |
| GET    | `/experiences`      | any user     | Published experiences. Filters: `kind`, `country` (ISO-2), `q`; paginated `page`/`per_page` |
| GET    | `/experiences/:id`  | any user     | One experience by numeric id **or** slug            |
| GET    | `/coverage`         | any user     | Map markers: per-country active/upcoming counts + coords |
| GET    | `/clients`          | agency       | Agency's own clients                                 |
| POST   | `/clients`          | agency       | Create a client                                     |
| GET    | `/clients/:id`      | agency       | Show a client                                       |
| PATCH  | `/clients/:id`      | agency       | Update a client                                     |
| DELETE | `/clients/:id`      | agency       | Delete a client                                     |
| GET    | `/bookings`         | agency       | Agency's bookings + commission `summary`. Filter: `status` |
| POST   | `/bookings`         | agency       | Book an experience (amount + commission auto-computed) |
| GET    | `/bookings/:id`     | agency       | Show a booking                                      |
| PATCH  | `/bookings/:id`     | agency       | Update `status` / `guests` / `notes`                |

Health check: `GET /up`.

### Errors

All errors return `{ "error": "message" }` (validation failures add a
`details: [...]` array) with the matching HTTP status (`401`, `403`, `404`,
`422`, `400`).

## Domain model

```
Organization (kind: hotel | agency | admin)
 ├─ has_many :users        (login accounts; has_secure_password)
 ├─ has_many :hotels       (hotel orgs — "centers of evolution")
 │            └─ has_many :experiences (retreat | masterclass | corporate)
 ├─ has_many :clients      (agency orgs — their end customers)
 └─ has_many :bookings     (agency books an experience for a client)
```

Bookings derive `amount_cents` (experience price × guests) and
`commission_cents` (× the experience's `commission_rate`) on save.

The seed data mirrors the four experiences and the *Viajes Éter* agency shown in
the `humana-app` dashboard so the two run together with no extra setup.
