# HUMANA seed data — minimal setup for production / live demos.
# Creates only the platform essentials. All other data is created
# through the app itself (invitations, onboarding, etc.).
#
# Idempotent: safe to run repeatedly via `bin/rails db:seed`.
# Runs automatically on every deploy via bin/docker-entrypoint.

puts "Seeding HUMANA platform essentials..."

# --- Purge old demo/seed data (one-time cleanup) ----------------------------
# Safe: only deletes data that was created by the old seeds.
# After this runs once, subsequent deploys skip it (nothing to delete).
admin_org_id = Organization.find_by(kind: "admin")&.id
admin_user_ids = admin_org_id ? User.where(organization_id: admin_org_id).pluck(:id) : []

non_admin_orgs = Organization.where.not(id: admin_org_id)
if non_admin_orgs.exists?
  puts "  Purging old seed data..."
  Booking.delete_all
  Client.delete_all
  Experience.delete_all
  RetreatActivity.delete_all
  RetreatDay.delete_all
  RetreatFacilitator.delete_all
  RetreatInclusion.delete_all
  RetreatPricing.delete_all
  RetreatImage.delete_all
  Retreat.delete_all
  RoomImage.delete_all
  AvailabilityBlock.delete_all
  Room.delete_all
  RoomType.delete_all
  HotelAmenity.delete_all
  HotelImage.delete_all
  Hotel.delete_all
  Subscription.delete_all
  StripeConnectAccount.delete_all
  Invitation.delete_all
  User.where.not(id: admin_user_ids).delete_all
  non_admin_orgs.delete_all
  puts "  Done purging."
end

# --- Platform admin ----------------------------------------------------------
admin_org = Organization.find_or_create_by!(name: "HUMANA Global") do |o|
  o.kind = "admin"
  o.status = "verified"
  o.city = "Madrid"
  o.country = "España"
  o.country_code = "ES"
  o.contact_email = "info@humana.global"
end

User.find_or_initialize_by(email: "admin@humana.global").tap do |u|
  u.organization = admin_org
  u.name = "Ariel Rinaldelli"
  u.role = "admin"
  u.locale = "en"
  u.password = "humana1234" if u.new_record?
  u.save!
end

# --- Platform settings -------------------------------------------------------
PlatformSetting.find_or_create_by!(platform_name: "HUMANA") do |ps|
  ps.support_email = "info@humana.global"
  ps.default_currency = "USD"
  ps.default_language = "en"
  ps.agency_commission_rate = 0.16
  ps.office_fee_rate = 0.02
  ps.hotel_net_rate = 0.82
end

# --- Countries ---------------------------------------------------------------
countries_data = [
  { name: "España", code: "ES", flag_emoji: "\u{1F1EA}\u{1F1F8}", region: "Europe", currency_code: "EUR", timezone: "Europe/Madrid" },
  { name: "Colombia", code: "CO", flag_emoji: "\u{1F1E8}\u{1F1F4}", region: "LATAM", currency_code: "COP", timezone: "America/Bogota" },
  { name: "Ecuador", code: "EC", flag_emoji: "\u{1F1EA}\u{1F1E8}", region: "LATAM", currency_code: "USD", timezone: "America/Guayaquil" },
  { name: "Perú", code: "PE", flag_emoji: "\u{1F1F5}\u{1F1EA}", region: "LATAM", currency_code: "PEN", timezone: "America/Lima" },
  { name: "Brasil", code: "BR", flag_emoji: "\u{1F1E7}\u{1F1F7}", region: "LATAM", currency_code: "BRL", timezone: "America/Sao_Paulo" },
  { name: "Paraguay", code: "PY", flag_emoji: "\u{1F1F5}\u{1F1FE}", region: "LATAM", currency_code: "PYG", timezone: "America/Asuncion" },
  { name: "Chile", code: "CL", flag_emoji: "\u{1F1E8}\u{1F1F1}", region: "LATAM", currency_code: "CLP", timezone: "America/Santiago" },
  { name: "Argentina", code: "AR", flag_emoji: "\u{1F1E6}\u{1F1F7}", region: "LATAM", currency_code: "ARS", timezone: "America/Argentina/Buenos_Aires" },
  { name: "Uruguay", code: "UY", flag_emoji: "\u{1F1FA}\u{1F1FE}", region: "LATAM", currency_code: "UYU", timezone: "America/Montevideo" },
  { name: "Costa Rica", code: "CR", flag_emoji: "\u{1F1E8}\u{1F1F7}", region: "LATAM", currency_code: "CRC", timezone: "America/Costa_Rica" },
  { name: "El Salvador", code: "SV", flag_emoji: "\u{1F1F8}\u{1F1FB}", region: "LATAM", currency_code: "USD", timezone: "America/El_Salvador" },
  { name: "Panamá", code: "PA", flag_emoji: "\u{1F1F5}\u{1F1E6}", region: "LATAM", currency_code: "USD", timezone: "America/Panama" },
  { name: "República Dominicana", code: "DO", flag_emoji: "\u{1F1E9}\u{1F1F4}", region: "LATAM", currency_code: "DOP", timezone: "America/Santo_Domingo" },
  { name: "Estados Unidos", code: "US", flag_emoji: "\u{1F1FA}\u{1F1F8}", region: "North America", currency_code: "USD", timezone: "America/New_York" },
  { name: "México", code: "MX", flag_emoji: "\u{1F1F2}\u{1F1FD}", region: "LATAM", currency_code: "MXN", timezone: "America/Mexico_City" },
]

# Disable countries that are no longer in the target list
target_codes = countries_data.map { |c| c[:code] }
Country.where.not(code: target_codes).update_all(enabled: false, status: "inactive")

countries_data.each do |attrs|
  country = Country.find_or_initialize_by(code: attrs[:code])
  country.assign_attributes(attrs.except(:code))
  country.status = "active"
  country.enabled = true
  country.save!
end

# --- Subscription plans ------------------------------------------------------
# Agency: $2,000/month or $15,000/year
# Hotel:  $3,000/month or $25,000/year

SubscriptionPlan.where.not(name: [
  "Agency Monthly", "Agency Annual", "Hotel Monthly", "Hotel Annual"
]).destroy_all

agency_plans = [
  { name: "Agency Monthly", price_cents: 200_000, billing_interval: "monthly",
    commission_rate: 0.16, trial_days: 14, position: 0,
    target_audience: "agency",
    features: { max_bookings: -1, max_clients: -1, support: "priority", analytics: "advanced" } },
  { name: "Agency Annual", price_cents: 1_500_000, billing_interval: "yearly",
    commission_rate: 0.16, trial_days: 14, position: 1,
    target_audience: "agency",
    features: { max_bookings: -1, max_clients: -1, support: "priority", analytics: "advanced" } },
]

hotel_plans = [
  { name: "Hotel Monthly", price_cents: 300_000, billing_interval: "monthly",
    commission_rate: 0.16, trial_days: 14, position: 0,
    target_audience: "hotel",
    features: { unlimited_room_types: true, retreat_creation: true, analytics: true, support: "priority" } },
  { name: "Hotel Annual", price_cents: 2_500_000, billing_interval: "yearly",
    commission_rate: 0.16, trial_days: 14, position: 1,
    target_audience: "hotel",
    features: { unlimited_room_types: true, retreat_creation: true, analytics: true, support: "priority" } },
]

(agency_plans + hotel_plans).each do |attrs|
  plan = SubscriptionPlan.find_or_initialize_by(name: attrs[:name])
  plan.assign_attributes(attrs)
  plan.currency = "USD"
  plan.active = true
  plan.save!
end

# --- Stripe Products + Prices (sandbox) ----------------------------------------
# Auto-creates Stripe Products and Prices for any plan missing a stripe_price_id.
# Requires STRIPE_SECRET_KEY in .env. Skips gracefully if not configured.

if ENV["STRIPE_SECRET_KEY"].present?
  plans_needing_stripe = SubscriptionPlan.where(stripe_price_id: [nil, ""])
  if plans_needing_stripe.any?
    puts "  Creating Stripe Products & Prices for #{plans_needing_stripe.count} plan(s)..."
    plans_needing_stripe.find_each do |plan|
      product = Stripe::Product.create(
        name: plan.name,
        metadata: { humana_plan_id: plan.id, target_audience: plan.target_audience }
      )

      interval = plan.billing_interval == "yearly" ? "year" : "month"
      price = Stripe::Price.create(
        product: product.id,
        unit_amount: plan.price_cents,
        currency: plan.currency.downcase,
        recurring: { interval: interval }
      )

      plan.update!(stripe_price_id: price.id)
      puts "    ✓ #{plan.name} → #{price.id}"
    end
  else
    puts "  Stripe: all plans already have stripe_price_id"
  end
else
  puts "  ⚠ STRIPE_SECRET_KEY not set — skipping Stripe Product/Price creation"
end

puts "Done."
puts "  Organizations: #{Organization.count}"
puts "  Users:         #{User.count}"
puts "  Countries:     #{Country.count}"
puts "  Sub Plans:     #{SubscriptionPlan.count}"
puts ""
puts "Login: admin@humana.global / humana1234"

# --- Development-only test data -----------------------------------------------
if Rails.env.development?
  load Rails.root.join("db/seeds/development.rb")
end
