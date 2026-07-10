# HUMANA seed data — minimal setup for production / live demos.
# Creates only the platform essentials. All other data is created
# through the app itself (invitations, onboarding, etc.).
#
# Idempotent: safe to run repeatedly via `bin/rails db:seed`.

puts "Seeding HUMANA platform essentials..."

# --- Platform admin ----------------------------------------------------------
admin_org = Organization.find_or_create_by!(name: "HUMANA Global") do |o|
  o.kind = "admin"
  o.status = "verified"
  o.city = "Madrid"
  o.country = "Spain"
  o.country_code = "ES"
  o.contact_email = "ops@humana.global"
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
  ps.support_email = "ops@humana.global"
  ps.default_currency = "USD"
  ps.default_language = "en"
  ps.agency_commission_rate = 0.16
  ps.office_fee_rate = 0.02
  ps.hotel_net_rate = 0.82
end

# --- Countries ---------------------------------------------------------------
countries_data = [
  { name: "Spain", code: "ES", flag_emoji: "\u{1F1EA}\u{1F1F8}", region: "Europe", currency_code: "EUR", timezone: "Europe/Madrid" },
  { name: "Mexico", code: "MX", flag_emoji: "\u{1F1F2}\u{1F1FD}", region: "LATAM", currency_code: "MXN", timezone: "America/Mexico_City" },
  { name: "Singapore", code: "SG", flag_emoji: "\u{1F1F8}\u{1F1EC}", region: "APAC", currency_code: "SGD", timezone: "Asia/Singapore" },
  { name: "Indonesia", code: "ID", flag_emoji: "\u{1F1EE}\u{1F1E9}", region: "APAC", currency_code: "IDR", timezone: "Asia/Jakarta" },
  { name: "Costa Rica", code: "CR", flag_emoji: "\u{1F1E8}\u{1F1F7}", region: "LATAM", currency_code: "CRC", timezone: "America/Costa_Rica" },
  { name: "Portugal", code: "PT", flag_emoji: "\u{1F1F5}\u{1F1F9}", region: "Europe", currency_code: "EUR", timezone: "Europe/Lisbon" },
  { name: "Thailand", code: "TH", flag_emoji: "\u{1F1F9}\u{1F1ED}", region: "APAC", currency_code: "THB", timezone: "Asia/Bangkok" },
  { name: "Peru", code: "PE", flag_emoji: "\u{1F1F5}\u{1F1EA}", region: "LATAM", currency_code: "PEN", timezone: "America/Lima" },
  { name: "Colombia", code: "CO", flag_emoji: "\u{1F1E8}\u{1F1F4}", region: "LATAM", currency_code: "COP", timezone: "America/Bogota" },
  { name: "Italy", code: "IT", flag_emoji: "\u{1F1EE}\u{1F1F9}", region: "Europe", currency_code: "EUR", timezone: "Europe/Rome" },
  { name: "Greece", code: "GR", flag_emoji: "\u{1F1EC}\u{1F1F7}", region: "Europe", currency_code: "EUR", timezone: "Europe/Athens" },
  { name: "India", code: "IN", flag_emoji: "\u{1F1EE}\u{1F1F3}", region: "APAC", currency_code: "INR", timezone: "Asia/Kolkata" }
]

countries_data.each do |attrs|
  Country.find_or_create_by!(code: attrs[:code]) do |c|
    c.name = attrs[:name]
    c.flag_emoji = attrs[:flag_emoji]
    c.region = attrs[:region]
    c.currency_code = attrs[:currency_code]
    c.timezone = attrs[:timezone]
    c.status = "active"
    c.enabled = true
  end
end

# --- Subscription plans ------------------------------------------------------
plans_data = [
  { name: "Starter", price_cents: 0, commission_rate: 0.16, trial_days: 14, position: 0,
    target_audience: "agency",
    features: { max_bookings: 10, max_clients: 50, support: "email", analytics: "basic" } },
  { name: "Professional", price_cents: 9900, commission_rate: 0.16, trial_days: 14, position: 1,
    target_audience: "agency",
    features: { max_bookings: -1, max_clients: -1, support: "priority", analytics: "advanced",
                custom_branding: true, api_access: true } },
  { name: "Enterprise", price_cents: 29900, commission_rate: 0.16, trial_days: 30, position: 2,
    target_audience: "agency",
    features: { max_bookings: -1, max_clients: -1, support: "dedicated", analytics: "full",
                custom_branding: true, api_access: true, white_label: true, sla: "99.9%" } }
]

plans_data.each do |attrs|
  SubscriptionPlan.find_or_create_by!(name: attrs[:name]) do |p|
    p.assign_attributes(attrs)
    p.currency = "USD"
    p.billing_interval = "monthly"
    p.active = true
  end
end

puts "Done."
puts "  Organizations: #{Organization.count}"
puts "  Users:         #{User.count}"
puts "  Countries:     #{Country.count}"
puts "  Sub Plans:     #{SubscriptionPlan.count}"
puts ""
puts "Login: admin@humana.global / humana1234"
