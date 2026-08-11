# HUMANA seed data — minimal setup for production / live demos.
# Creates only the platform essentials. All other data is created
# through the app itself (invitations, onboarding, etc.).
#
# Idempotent: safe to run repeatedly via `bin/rails db:seed`.
# Runs automatically on every deploy via bin/docker-entrypoint.

puts "Seeding HUMANA platform essentials..."

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

# --- Demo hotel (partner for retreat booking flow) ----------------------------

hotel_org = Organization.find_or_create_by!(name: "SHA Wellness Clinic") do |o|
  o.kind = "hotel"
  o.status = "verified"
  o.city = "Altea"
  o.country = "España"
  o.country_code = "ES"
  o.contact_email = "info@shawellness.com"
  o.website = "https://shawellnessclinic.com"
  o.onboarding_completed_at = Time.current
end

User.find_or_initialize_by(email: "hotel@shawellness.com").tap do |u|
  u.organization = hotel_org
  u.name = "Claudia Martínez"
  u.role = "owner"
  u.locale = "es"
  u.status = "active"
  u.onboarding_completed_at = Time.current
  u.password = "humana1234" if u.new_record?
  u.save!
end

sha_hotel = Hotel.find_or_create_by!(name: "SHA Wellness Clinic", organization: hotel_org) do |h|
  h.city = "Altea"
  h.country = "España"
  h.country_code = "ES"
  h.latitude = 38.5988
  h.longitude = -0.0471
  h.certified = true
  h.wellness_standard = "Medical Wellness"
  h.description = "World-renowned integrative wellness clinic combining cutting-edge Western medicine with ancient Eastern therapies."
  h.address = "Carrer del Verderol 5, El Albir"
  h.postal_code = "03581"
  h.phone = "+34 966 81 11 99"
  h.stars = 5
  h.check_in_time = "15:00"
  h.check_out_time = "12:00"
  h.total_rooms = 120
  h.contact_email = "info@shawellness.com"
  h.website = "https://shawellnessclinic.com"
  h.onboarding_completed_at = Time.current
end

# Room types
suite = RoomType.find_or_create_by!(hotel: sha_hotel, name: "SHA Suite") do |rt|
  rt.category = "suite"
  rt.capacity = 2
  rt.area_sqm = 65
  rt.price_per_night_cents = 85_000
  rt.currency = "USD"
  rt.description = "Spacious suite with Mediterranean views, private terrace, and marble bathroom."
  rt.bed_type = "king"
  rt.view_type = "sea_view"
  rt.amenities = ["wifi", "minibar", "safe", "air_conditioning", "bathrobe", "terrace"]
  rt.total_rooms = 30
  rt.position = 0
end

deluxe = RoomType.find_or_create_by!(hotel: sha_hotel, name: "Deluxe Room") do |rt|
  rt.category = "superior"
  rt.capacity = 2
  rt.area_sqm = 45
  rt.price_per_night_cents = 55_000
  rt.currency = "USD"
  rt.description = "Elegant room with garden views and modern wellness amenities."
  rt.bed_type = "queen"
  rt.view_type = "garden_view"
  rt.amenities = ["wifi", "minibar", "safe", "air_conditioning", "bathrobe"]
  rt.total_rooms = 50
  rt.position = 1
end

superior = RoomType.find_or_create_by!(hotel: sha_hotel, name: "Superior Room") do |rt|
  rt.category = "standard"
  rt.capacity = 2
  rt.area_sqm = 35
  rt.price_per_night_cents = 38_000
  rt.currency = "USD"
  rt.description = "Comfortable room with all essential wellness amenities."
  rt.bed_type = "queen"
  rt.view_type = "mountain_view"
  rt.amenities = ["wifi", "safe", "air_conditioning"]
  rt.total_rooms = 40
  rt.position = 2
end

# Create physical rooms for availability tracking (5 per type for demo)
[suite, deluxe, superior].each do |rt|
  5.times do |i|
    Room.find_or_create_by!(hotel: sha_hotel, room_type: rt, number: "#{rt.name[0..2].upcase}-#{100 + i}")
  end
end

# Hotel amenities
[
  { name: "Infinity Pool", category: "wellness", featured: true, position: 0 },
  { name: "Thermal Circuit", category: "wellness", featured: true, position: 1 },
  { name: "Meditation Garden", category: "wellness", featured: true, position: 2 },
  { name: "Organic Restaurant", category: "dining", featured: true, position: 3 },
  { name: "Fitness Center", category: "recreation", featured: false, position: 4 },
  { name: "Yoga Studio", category: "wellness", featured: false, position: 5 },
].each do |attrs|
  HotelAmenity.find_or_create_by!(hotel: sha_hotel, name: attrs[:name]) do |a|
    a.category = attrs[:category]
    a.featured = attrs[:featured]
    a.position = attrs[:position]
  end
end

# An experience at this hotel (for the retreat-via-experience booking path)
exp = Experience.find_or_initialize_by(slug: "sha-detox-reset").tap do |e|
  e.hotel = sha_hotel
  e.kind = "wellness"
  e.title = "SHA Detox & Reset"
  e.description = "A transformative 5-night detoxification program combining macrobiotic nutrition, natural therapies, and cognitive health."
  e.location = "Altea, Spain"
  e.country = "España"
  e.country_code = "ES"
  e.starts_on = 8.weeks.from_now.to_date
  e.ends_on = 8.weeks.from_now.to_date + 5.days
  e.price_cents = 450_000
  e.currency = "USD"
  e.commission_rate = 0.16
  e.capacity = 20
  e.status = "active"
  e.save!
end

# --- Demo agency (Viajes Éter) -----------------------------------------------

agency_org = Organization.find_or_create_by!(name: "Viajes Éter") do |o|
  o.kind = "agency"
  o.status = "verified"
  o.city = "Buenos Aires"
  o.country = "Argentina"
  o.country_code = "AR"
  o.contact_email = "info@viajeseter.com"
  o.website = "https://viajeseter.com"
  o.legal_name = "Viajes Éter S.R.L."
  o.phone = "+54 11 5555-1234"
  o.tax_id = "30-71234567-9"
  o.onboarding_completed_at = Time.current
end

User.find_or_initialize_by(email: "agent@viajeseter.com").tap do |u|
  u.organization = agency_org
  u.name = "María González"
  u.role = "owner"
  u.locale = "es"
  u.status = "active"
  u.onboarding_completed_at = Time.current
  u.password = "humana1234" if u.new_record?
  u.save!
end

# Give agency an active subscription
agency_plan = SubscriptionPlan.find_by(name: "Agency Monthly")
if agency_plan
  Subscription.find_or_create_by!(organization: agency_org, subscription_plan: agency_plan) do |s|
    s.status = "active"
    s.current_period_start = Time.current
    s.current_period_end = 30.days.from_now
  end
end

# Agency clients
client1 = Client.find_or_create_by!(organization: agency_org, email: "carlos@example.com") do |c|
  c.name = "Carlos Méndez"
  c.phone = "+54 11 4444-0001"
  c.notes = "Interested in wellness retreats. Has back pain issues."
end

client2 = Client.find_or_create_by!(organization: agency_org, email: "laura@example.com") do |c|
  c.name = "Laura Sánchez"
  c.phone = "+54 11 4444-0002"
  c.notes = "Repeat customer. Prefers luxury suites."
end

client3 = Client.find_or_create_by!(organization: agency_org, email: "diego@example.com") do |c|
  c.name = "Diego Fernández"
  c.phone = "+54 11 4444-0003"
end

# --- Inventory blocks (agency allotments at SHA hotel) -----------------------
# Create room allotments for ALL agency organizations so every agency user
# has inventory available when testing the retreat creation wizard.

room_costs = { suite => 65_000, deluxe => 42_000, superior => 28_000 }
room_allotments = { suite => 5, deluxe => 8, superior => 10 }

Organization.where(kind: "agency").find_each do |agency|
  [suite, deluxe, superior].each do |rt|
    InventoryBlock.find_or_initialize_by(organization: agency, hotel: sha_hotel, room_type: rt).tap do |ib|
      ib.total_rooms = room_allotments[rt]
      ib.starts_on = Date.today
      ib.ends_on = 6.months.from_now.to_date
      ib.cost_per_night_cents = room_costs[rt]
      ib.currency = "USD"
      ib.status = "active"
      ib.save!
    end
  end
  puts "  ✓ Inventory blocks (3 room types at SHA for #{agency.name})"
end

# --- Agency-created retreat at SHA hotel -------------------------------------
# This is the key scenario: Viajes Éter created a retreat using SHA as venue.
# Other agencies (or Viajes Éter itself) can book spots.

retreat = Retreat.find_or_initialize_by(slug: "mindfulness-mediterranean").tap do |r|
  r.hotel = sha_hotel
  r.created_by_organization = agency_org
  r.created_by_type = "agency"
  r.name = "Mindfulness & Mediterranean Wellness"
  r.retreat_type = "mindfulness"
  r.duration_nights = 4
  r.starts_on = 6.weeks.from_now.to_date
  r.ends_on = 6.weeks.from_now.to_date + 4.days
  r.capacity = 16
  r.language = "es"
  r.status = "active"
  r.description = "An immersive 4-night mindfulness retreat on the Mediterranean coast. Guided meditation sessions at sunrise, mindful movement classes, sound healing ceremonies, and conscious nutrition workshops — all set against the stunning backdrop of Altea's coastline."
  r.short_description = "4-night immersive mindfulness retreat on the Spanish Mediterranean coast."
  r.location = "Altea, Spain"
  r.country = "España"
  r.country_code = "ES"
  r.currency = "USD"
  r.commission_rate = 0.16
  r.featured = true
  r.certified = true
  r.published_at = 2.weeks.ago
  r.save!
end

# Retreat pricing per room type
RetreatPricing.find_or_create_by!(retreat: retreat, room_type: suite) do |rp|
  rp.price_per_guest_cents = 320_000
  rp.currency = "USD"
  rp.occupancy_label = "Single/Double"
  rp.max_guests = 2
end

RetreatPricing.find_or_create_by!(retreat: retreat, room_type: deluxe) do |rp|
  rp.price_per_guest_cents = 240_000
  rp.currency = "USD"
  rp.occupancy_label = "Single/Double"
  rp.max_guests = 2
end

RetreatPricing.find_or_create_by!(retreat: retreat, room_type: superior) do |rp|
  rp.price_per_guest_cents = 180_000
  rp.currency = "USD"
  rp.occupancy_label = "Single/Double"
  rp.max_guests = 2
end

# Retreat program (4 days)
[
  { day_number: 1, title: "Arrival & Grounding", activities: [
    { name: "Welcome Circle", time: "16:00", duration_minutes: 60, category: "ceremony" },
    { name: "Sunset Meditation", time: "18:30", duration_minutes: 45, category: "meditation" },
    { name: "Conscious Dinner", time: "20:00", duration_minutes: 90, category: "meal" },
  ]},
  { day_number: 2, title: "Deep Practice", activities: [
    { name: "Sunrise Meditation", time: "07:00", duration_minutes: 60, category: "meditation" },
    { name: "Mindful Movement", time: "09:00", duration_minutes: 75, category: "yoga" },
    { name: "Sound Healing", time: "16:00", duration_minutes: 60, category: "spa" },
    { name: "Evening Journaling", time: "20:00", duration_minutes: 45, category: "workshop" },
  ]},
  { day_number: 3, title: "Integration", activities: [
    { name: "Walking Meditation", time: "07:30", duration_minutes: 60, category: "meditation" },
    { name: "Breathwork Session", time: "10:00", duration_minutes: 75, category: "breathwork" },
    { name: "Free Spa Time", time: "14:00", duration_minutes: 120, category: "free_time" },
    { name: "Group Sharing Circle", time: "18:00", duration_minutes: 60, category: "ceremony" },
  ]},
  { day_number: 4, title: "Farewell & Renewal", activities: [
    { name: "Final Meditation", time: "07:00", duration_minutes: 60, category: "meditation" },
    { name: "Closing Ceremony", time: "10:00", duration_minutes: 90, category: "ceremony" },
  ]},
].each do |day_data|
  day = RetreatDay.find_or_create_by!(retreat: retreat, day_number: day_data[:day_number]) do |d|
    d.title = day_data[:title]
  end
  day_data[:activities].each_with_index do |act, idx|
    RetreatActivity.find_or_create_by!(retreat_day: day, name: act[:name]) do |a|
      a.time = act[:time]
      a.duration_minutes = act[:duration_minutes]
      a.category = act[:category]
      a.position = idx
    end
  end
end

# Retreat facilitators
RetreatFacilitator.find_or_create_by!(retreat: retreat, name: "Elena Voss") do |f|
  f.role = "lead"
  f.specialty = "Mindfulness & MBSR"
  f.bio = "Certified MBSR instructor with 15 years of experience leading retreats across Europe and Latin America."
  f.position = 0
end

RetreatFacilitator.find_or_create_by!(retreat: retreat, name: "Tomás Aguirre") do |f|
  f.role = "assistant"
  f.specialty = "Sound Healing & Breathwork"
  f.bio = "Sound healer and breathwork facilitator trained in Wim Hof and holotropic techniques."
  f.position = 1
end

# Retreat inclusions
[
  { name: "All meditation sessions", category: "activity" },
  { name: "Welcome & closing ceremonies", category: "activity" },
  { name: "Full-board macrobiotic meals", category: "meal" },
  { name: "Daily spa access", category: "wellness" },
  { name: "Program materials & journal", category: "equipment" },
  { name: "Airport transfer", category: "transport" },
].each_with_index do |inc, idx|
  RetreatInclusion.find_or_create_by!(retreat: retreat, name: inc[:name]) do |ri|
    ri.category = inc[:category]
    ri.position = idx
  end
end

# --- Sample bookings for agency (to populate booking history & billing) -------

# Booking 1: Carlos booked the SHA Detox experience (retreat via experience path)
Booking.find_or_initialize_by(organization: agency_org, experience: exp, client: client1).tap do |b|
  next unless b.new_record?
  b.hotel = sha_hotel
  b.room_type = deluxe
  b.guests = 1
  b.status = "confirmed"
  b.notes = "Client requested ground floor"
  b.starts_on = exp.starts_on
  b.ends_on = exp.ends_on
  b.save!
end

# Booking 2: Laura booked a direct hotel stay (lodging path)
Booking.find_or_initialize_by(organization: agency_org, hotel: sha_hotel, client: client2, experience: nil, retreat: nil).tap do |b|
  next unless b.new_record?
  b.room_type = suite
  b.guests = 2
  b.status = "confirmed"
  b.starts_on = 4.weeks.from_now.to_date
  b.ends_on = 4.weeks.from_now.to_date + 3.days
  b.save!
end

# --- Second agency (for testing "another agency buys your retreat" flow) ------

agency2_org = Organization.find_or_create_by!(name: "Wellness Horizons") do |o|
  o.kind = "agency"
  o.status = "verified"
  o.city = "Madrid"
  o.country = "España"
  o.country_code = "ES"
  o.contact_email = "hello@wellnesshorizons.com"
  o.onboarding_completed_at = Time.current
end

User.find_or_initialize_by(email: "agent@wellnesshorizons.com").tap do |u|
  u.organization = agency2_org
  u.name = "Pablo Romero"
  u.role = "owner"
  u.locale = "en"
  u.status = "active"
  u.onboarding_completed_at = Time.current
  u.password = "humana1234" if u.new_record?
  u.save!
end

# Give second agency a subscription too
if agency_plan
  Subscription.find_or_create_by!(organization: agency2_org, subscription_plan: agency_plan) do |s|
    s.status = "active"
    s.current_period_start = Time.current
    s.current_period_end = 30.days.from_now
  end
end

# Second agency's client books the Mindfulness retreat created by Viajes Éter
wh_client = Client.find_or_create_by!(organization: agency2_org, email: "sophie@example.com") do |c|
  c.name = "Sophie Martin"
  c.phone = "+34 600 111 222"
end

Booking.find_or_initialize_by(organization: agency2_org, retreat: retreat, client: wh_client).tap do |b|
  next unless b.new_record?
  b.hotel = sha_hotel
  b.room_type = suite
  b.guests = 1
  b.status = "confirmed"
  b.starts_on = retreat.starts_on
  b.ends_on = retreat.ends_on
  # amount & commission computed by model callback
  b.amount_cents = suite.price_per_night_cents * retreat.duration_nights
  b.commission_cents = (b.amount_cents * 0.16).round
  b.currency = "USD"
  b.save!
end

puts "Done."
puts "  Organizations: #{Organization.count}"
puts "  Users:         #{User.count}"
puts "  Hotels:        #{Hotel.count}"
puts "  Room Types:    #{RoomType.count}"
puts "  Experiences:   #{Experience.count}"
puts "  Retreats:      #{Retreat.count}"
puts "  Clients:       #{Client.count}"
puts "  Bookings:      #{Booking.count}"
puts "  Countries:     #{Country.count}"
puts "  Sub Plans:     #{SubscriptionPlan.count}"
puts "  Subscriptions: #{Subscription.count}"
puts ""
puts "Login credentials (all: humana1234):"
puts "  Admin:  admin@humana.global"
puts "  Agency: agent@viajeseter.com"
puts "  Hotel:  hotel@shawellness.com"
puts "  Agency2: agent@wellnesshorizons.com"

