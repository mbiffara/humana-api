# HUMANA seed data — mirrors the experiences and agency shown in the Next.js
# front-end (humana-app) so the two line up out of the box.
#
# Idempotent: safe to run repeatedly via `bin/rails db:seed`.

puts "Seeding HUMANA network..."

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

# --- Agency (Viajes Éter · Madrid, matches the dashboard) --------------------
agency = Organization.find_or_create_by!(name: "Viajes Éter") do |o|
  o.kind = "agency"
  o.status = "verified"
  o.city = "Madrid"
  o.country = "Spain"
  o.country_code = "ES"
  o.contact_email = "hola@viajeseter.com"
  o.website = "https://viajeseter.com"
end

User.find_or_initialize_by(email: "agent@viajeseter.com").tap do |u|
  u.organization = agency
  u.name = "Valentina Esposito"
  u.role = "owner"
  u.locale = "es"
  u.password = "humana1234" if u.new_record?
  u.save!
end

# --- Hotels (centers of evolution) + their experiences -----------------------
# Coordinates roughly match the dashboard map markers.
catalog = [
  {
    org: "Casa del Faro Collection",
    hotel: { name: "Casa del Faro", city: "Ibiza", country: "Spain", country_code: "ES",
             latitude: 38.9067, longitude: 1.4206, wellness_standard: "Global Wellness Institute" },
    experience: {
      slug: "mediterranean-silence", kind: "retreat", title: "Mediterranean Silence",
      location: "Ibiza · Spain", country: "Spain", country_code: "ES",
      starts_on: Date.new(2026, 5, 12), ends_on: Date.new(2026, 5, 19),
      price_cents: 524_000, commission_rate: 0.12, capacity: 24, status: "active",
      image_url: "/images/retreat-ibiza.jpg",
      description: "Conscious breathing, guided fasting and cliffside meditation sessions. " \
                   "Program certified by Global Wellness Institute."
    }
  },
  {
    org: "Itzamná Hospitality",
    hotel: { name: "Hotel Itzamná", city: "Tulum", country: "Mexico", country_code: "MX",
             latitude: 20.2114, longitude: -87.4654, wellness_standard: "Global Wellness Institute" },
    experience: {
      slug: "root-and-ceremony", kind: "masterclass", title: "Root and Ceremony",
      location: "Tulum · Mexico", country: "Mexico", country_code: "MX",
      starts_on: Date.new(2026, 5, 28), ends_on: Date.new(2026, 6, 1),
      price_cents: 346_000, commission_rate: 0.15, capacity: 18, status: "active",
      image_url: "/images/retreat-tulum.jpg",
      description: "Immersion in ancestral Mayan medicine, sunrise yoga and cacao circles " \
                   "guided by certified facilitators."
    }
  },
  {
    org: "Marina Bay Sanctuary Group",
    hotel: { name: "Marina Bay Sanctuary", city: "Singapore", country: "Singapore", country_code: "SG",
             latitude: 1.2834, longitude: 103.8607, wellness_standard: "Global Wellness Institute" },
    experience: {
      slug: "conscious-leadership", kind: "corporate", title: "Conscious Leadership",
      location: "Singapore", country: "Singapore", country_code: "SG",
      starts_on: Date.new(2026, 6, 9), ends_on: Date.new(2026, 6, 12),
      price_cents: 691_000, commission_rate: 0.10, capacity: 30, status: "upcoming",
      image_url: "/images/retreat-singapore.jpg",
      description: "Executive retreat for leadership teams. Somatic coaching, strategic sessions " \
                   "and vertical integration spaces."
    }
  },
  {
    org: "Ananda Villas",
    hotel: { name: "Ananda Villa", city: "Ubud", country: "Indonesia", country_code: "ID",
             latitude: -8.5069, longitude: 115.2625, wellness_standard: "Global Wellness Institute" },
    experience: {
      slug: "ubud-roots", kind: "masterclass", title: "Ubud Roots",
      location: "Ubud · Bali", country: "Indonesia", country_code: "ID",
      starts_on: Date.new(2026, 7, 2), ends_on: Date.new(2026, 7, 7),
      price_cents: 458_000, commission_rate: 0.13, capacity: 20, status: "upcoming",
      image_url: "/images/retreat-bali.jpg",
      description: "Rainforest immersion, plant-based cuisine masterclass and breathwork " \
                   "with Balinese practitioners."
    }
  }
]

experiences = catalog.map do |entry|
  hotel_org = Organization.find_or_create_by!(name: entry[:org]) do |o|
    o.kind = "hotel"
    o.status = "verified"
    o.city = entry[:hotel][:city]
    o.country = entry[:hotel][:country]
    o.country_code = entry[:hotel][:country_code]
  end

  hotel = Hotel.find_or_create_by!(organization: hotel_org, name: entry[:hotel][:name]) do |h|
    h.assign_attributes(entry[:hotel].except(:name))
    h.certified = true
  end

  Experience.find_or_create_by!(slug: entry[:experience][:slug]) do |e|
    e.assign_attributes(entry[:experience])
    e.hotel = hotel
    e.currency = "USD"
  end
end

# --- A couple of clients and a sample booking for the agency ------------------
client = Client.find_or_create_by!(organization: agency, name: "Marina Solano") do |c|
  c.email = "marina.solano@example.com"
  c.phone = "+34 600 112 233"
end

Client.find_or_create_by!(organization: agency, name: "Grupo Lumen") do |c|
  c.email = "viajes@grupolumen.com"
  c.notes = "Corporate wellness program, 2026 offsite."
end

Booking.find_or_create_by!(organization: agency, experience: experiences.first) do |b|
  b.client = client
  b.guests = 2
  b.status = "confirmed"
end

# --- Office organizations (HUMANA regional offices) -------------------------
offices = [
  { name: "HUMANA LATAM", city: "Mexico City", country: "Mexico", country_code: "MX",
    contact_email: "latam@humana.global" },
  { name: "HUMANA Europe", city: "Madrid", country: "Spain", country_code: "ES",
    contact_email: "europe@humana.global" },
  { name: "HUMANA APAC", city: "Singapore", country: "Singapore", country_code: "SG",
    contact_email: "apac@humana.global" }
]

offices.each do |attrs|
  Organization.find_or_create_by!(name: attrs[:name]) do |o|
    o.kind = "office"
    o.status = "verified"
    o.city = attrs[:city]
    o.country = attrs[:country]
    o.country_code = attrs[:country_code]
    o.contact_email = attrs[:contact_email]
  end
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

# Give the agency a starter subscription
starter = SubscriptionPlan.find_by(name: "Starter")
if starter && !Subscription.exists?(organization: agency)
  Subscription.create!(
    organization: agency,
    subscription_plan: starter,
    status: "active",
    current_period_start: Time.current,
    current_period_end: 30.days.from_now
  )
end

# --- Room types for Casa del Faro -------------------------------------------
casa_del_faro = Hotel.find_by(name: "Casa del Faro")
if casa_del_faro && casa_del_faro.room_types.empty?
  [
    { name: "Garden Room", category: "standard", capacity: 2, area_sqm: 28,
      price_per_night_cents: 18000, position: 0,
      description: "Ground-floor room with private garden terrace and sea breeze." },
    { name: "Ocean Suite", category: "suite", capacity: 2, area_sqm: 45,
      price_per_night_cents: 32000, position: 1,
      description: "Panoramic Mediterranean views, separate living area, rainfall shower." },
    { name: "Cliff Villa", category: "villa", capacity: 4, area_sqm: 85,
      price_per_night_cents: 58000, position: 2,
      description: "Private infinity pool, two bedrooms, direct cliff path to beach." }
  ].each do |attrs|
    casa_del_faro.room_types.create!(attrs.merge(currency: "USD"))
  end
end

# --- Sample retreat for Casa del Faro (with full program) -------------------
if casa_del_faro && casa_del_faro.retreats.empty?
  hotel_org = casa_del_faro.organization
  retreat = Retreat.find_or_create_by!(slug: "mediterranean-silence-retreat") do |r|
    r.hotel = casa_del_faro
    r.created_by_organization = hotel_org
    r.created_by_type = "hotel"
    r.name = "Mediterranean Silence Retreat"
    r.retreat_type = "wellness"
    r.duration_nights = 7
    r.starts_on = Date.new(2026, 5, 12)
    r.ends_on = Date.new(2026, 5, 19)
    r.capacity = 24
    r.language = "en"
    r.status = "active"
    r.published_at = Time.current
    r.description = "A transformative 7-night immersion in conscious breathing, guided fasting, " \
                    "and cliffside meditation sessions overlooking the Mediterranean Sea."
    r.short_description = "Conscious breathing & cliffside meditation in Ibiza"
    r.location = "Ibiza, Spain"
    r.country = "Spain"
    r.country_code = "ES"
    r.currency = "USD"
    r.commission_rate = 0.12
    r.featured = true
    r.certified = true
  end

  # Days
  days_data = [
    { day_number: 1, title: "Arrival & Integration",
      activities: [
        { name: "Airport Transfer", time: "14:00", category: "check_in", position: 0 },
        { name: "Welcome Circle & Intentions", time: "17:00", category: "ceremony", position: 1 },
        { name: "Farm-to-Table Welcome Dinner", time: "19:30", category: "meal", position: 2 }
      ] },
    { day_number: 2, title: "Awakening the Body",
      activities: [
        { name: "Sunrise Pranayama", time: "06:30", category: "breathwork", position: 0, duration_minutes: 45 },
        { name: "Vinyasa Flow Yoga", time: "08:00", category: "yoga", position: 1, duration_minutes: 75 },
        { name: "Organic Brunch", time: "10:00", category: "meal", position: 2 },
        { name: "Mediterranean Cliff Walk", time: "11:30", category: "excursion", position: 3, duration_minutes: 90 },
        { name: "Silence Period", time: "14:00", category: "meditation", position: 4 },
        { name: "Sound Bath & Yoga Nidra", time: "17:00", category: "meditation", position: 5, duration_minutes: 60 },
        { name: "Plant-Based Dinner", time: "19:30", category: "meal", position: 6 }
      ] },
    { day_number: 3, title: "Deep Breath",
      activities: [
        { name: "Wim Hof Breathing", time: "07:00", category: "breathwork", position: 0, duration_minutes: 60 },
        { name: "Restorative Yoga", time: "08:30", category: "yoga", position: 1 },
        { name: "Brunch", time: "10:00", category: "meal", position: 2 },
        { name: "Journaling Workshop", time: "11:00", category: "workshop", position: 3 },
        { name: "Free Time & Spa", time: "14:00", category: "free_time", position: 4 },
        { name: "Guided Fasting Talk", time: "17:00", category: "workshop", position: 5 },
        { name: "Light Dinner", time: "19:00", category: "meal", position: 6 }
      ] },
    { day_number: 7, title: "Integration & Departure",
      activities: [
        { name: "Gratitude Meditation", time: "07:00", category: "meditation", position: 0 },
        { name: "Closing Circle", time: "09:00", category: "ceremony", position: 1 },
        { name: "Farewell Brunch", time: "10:30", category: "meal", position: 2 },
        { name: "Airport Transfer", time: "12:00", category: "check_out", position: 3 }
      ] }
  ]

  days_data.each do |day_attrs|
    activities = day_attrs.delete(:activities)
    day = retreat.retreat_days.find_or_create_by!(day_number: day_attrs[:day_number]) do |d|
      d.title = day_attrs[:title]
    end
    activities.each do |act_attrs|
      day.retreat_activities.find_or_create_by!(name: act_attrs[:name]) do |a|
        a.assign_attributes(act_attrs)
      end
    end
  end

  # Facilitators
  [
    { name: "Elena Rodríguez", role: "lead", specialty: "Pranayama & Breathwork",
      bio: "Certified breathwork facilitator with 15 years of experience across Europe and Asia.", position: 0 },
    { name: "Marco Bellini", role: "assistant", specialty: "Yoga & Somatic Movement",
      bio: "RYT-500 certified instructor specializing in Vinyasa and restorative yoga.", position: 1 },
    { name: "Dr. Amira Patel", role: "guest", specialty: "Fasting & Nutrition",
      bio: "Functional medicine doctor specializing in therapeutic fasting protocols.", position: 2 }
  ].each do |attrs|
    retreat.retreat_facilitators.find_or_create_by!(name: attrs[:name]) do |f|
      f.assign_attributes(attrs)
    end
  end

  # Inclusions
  [
    { name: "Full-board organic meals", category: "meal", position: 0 },
    { name: "Airport transfer (round trip)", category: "transport", position: 1 },
    { name: "Daily yoga & breathwork sessions", category: "wellness", position: 2 },
    { name: "Spa & sauna access", category: "amenity", position: 3 },
    { name: "Guided meditation sessions", category: "wellness", position: 4 },
    { name: "Welcome ceremony materials", category: "general", position: 5 },
    { name: "Organic teas & infusions", category: "meal", position: 6 }
  ].each do |attrs|
    retreat.retreat_inclusions.find_or_create_by!(name: attrs[:name]) do |inc|
      inc.assign_attributes(attrs)
    end
  end

  # Pricing by room type
  casa_del_faro.room_types.each_with_index do |rt, i|
    base_prices = [524_000, 680_000, 920_000]
    retreat.retreat_pricings.find_or_create_by!(room_type: rt) do |p|
      p.price_per_guest_cents = base_prices[i] || base_prices.last
      p.currency = "USD"
      p.occupancy_label = rt.capacity <= 2 ? "Double" : "Family"
      p.max_guests = rt.capacity
    end
  end

  # Images
  [
    { image_url: "/images/retreat-ibiza.jpg", position: 0, is_cover: true, alt_text: "Cliffside meditation terrace at sunset" },
    { image_url: "/images/retreat-ibiza-2.jpg", position: 1, alt_text: "Yoga pavilion overlooking the sea" },
    { image_url: "/images/retreat-ibiza-3.jpg", position: 2, alt_text: "Organic farm-to-table dining" }
  ].each do |attrs|
    retreat.retreat_images.find_or_create_by!(image_url: attrs[:image_url]) do |img|
      img.assign_attributes(attrs)
    end
  end
end

# --- Hotel user for Casa del Faro (for testing hotel dashboard) -------------
hotel_user_org = Organization.find_by(name: "Casa del Faro Collection")
if hotel_user_org
  User.find_or_initialize_by(email: "hotel@casadelfaro.com").tap do |u|
    u.organization = hotel_user_org
    u.name = "Carmen Vidal"
    u.role = "owner"
    u.locale = "es"
    u.password = "humana1234" if u.new_record?
    u.save!
  end
end

# --- Office user for HUMANA LATAM (for testing office dashboard) ------------
latam_office = Organization.find_by(name: "HUMANA LATAM")
if latam_office
  User.find_or_initialize_by(email: "office@humana.global").tap do |u|
    u.organization = latam_office
    u.name = "Diego Morales"
    u.role = "owner"
    u.locale = "es"
    u.password = "humana1234" if u.new_record?
    u.save!
  end
end

# --- Pending invitations (for dashboard testing) ----------------------------
admin_user = User.find_by(email: "admin@humana.global")

pending_invitations = [
  { email: "laura@lomareyes.com", role: "owner", org_kind: "agency", org_name: "Loma Reyes Travel",
    city: "Buenos Aires", country: "Argentina", country_code: "AR", days_ago: 2 },
  { email: "marco@vistamar.com", role: "owner", org_kind: "hotel", org_name: "Vista Mar Resort",
    city: "Cancun", country: "Mexico", country_code: "MX", days_ago: 5 },
  { email: "isabela@retiros.com", role: "owner", org_kind: "agency", org_name: "Retiros Naturales",
    city: "Bogota", country: "Colombia", country_code: "CO", days_ago: 1 },
  { email: "sofia@newdelhi.humana.global", role: "owner", org_kind: "office", org_name: "HUMANA India",
    city: "New Delhi", country: "India", country_code: "IN", days_ago: 3 },
]

pending_invitations.each do |attrs|
  org = Organization.find_or_create_by!(name: attrs[:org_name]) do |o|
    o.kind = attrs[:org_kind]
    o.status = "pending"
    o.city = attrs[:city]
    o.country = attrs[:country]
    o.country_code = attrs[:country_code]
  end

  unless Invitation.exists?(email: attrs[:email])
    Invitation.create!(
      email: attrs[:email],
      role: attrs[:role],
      organization: org,
      invited_by: admin_user,
      created_at: attrs[:days_ago].days.ago,
      expires_at: (7 - attrs[:days_ago]).days.from_now
    )
  end
end

# --- Pending organizations (approval queue) ---------------------------------
pending_orgs_data = [
  { name: "Serenity Hills Spa", kind: "hotel", city: "Cusco", country: "Peru", country_code: "PE",
    contact_email: "info@serenityhills.pe", days_ago: 1 },
  { name: "Aventura Global", kind: "agency", city: "Lima", country: "Peru", country_code: "PE",
    contact_email: "hola@aventuraglobal.com", days_ago: 3 },
  { name: "Zen Garden Hotel", kind: "hotel", city: "Chiang Mai", country: "Thailand", country_code: "TH",
    contact_email: "hello@zengarden.th", days_ago: 0 },
]

pending_orgs_data.each do |attrs|
  Organization.find_or_create_by!(name: attrs[:name]) do |o|
    o.kind = attrs[:kind]
    o.status = "pending"
    o.city = attrs[:city]
    o.country = attrs[:country]
    o.country_code = attrs[:country_code]
    o.contact_email = attrs[:contact_email]
    o.created_at = attrs[:days_ago].days.ago
  end
end

# --- Office-invited users (require admin approval) --------------------------
# These simulate invitations sent by office managers, NOT by the admin.
# All should be pending in the network page, requiring admin review.

office_user = User.find_by(email: "office@humana.global")

office_invited_data = [
  { email: "carlos@aventurazen.mx", role: "owner", org_kind: "agency", org_name: "Aventura Zen Travel",
    city: "Guadalajara", country: "Mexico", country_code: "MX", days_ago: 2,
    user_name: "Carlos Méndez", status: "pending" },
  { email: "ana@hotelceleste.mx", role: "owner", org_kind: "hotel", org_name: "Hotel Celeste",
    city: "Oaxaca", country: "Mexico", country_code: "MX", days_ago: 4,
    user_name: "Ana Lucía Reyes", status: "pending" },
  { email: "pedro@bienestarviajes.mx", role: "owner", org_kind: "agency", org_name: "Bienestar Viajes",
    city: "Monterrey", country: "Mexico", country_code: "MX", days_ago: 1,
    user_name: "Pedro Salinas", status: "pending" },
  { email: "maria@casasol.mx", role: "owner", org_kind: "hotel", org_name: "Casa Sol Wellness",
    city: "San Miguel de Allende", country: "Mexico", country_code: "MX", days_ago: 6,
    user_name: "María del Sol García", status: "pending" },
]

if office_user
  office_invited_data.each do |attrs|
    org = Organization.find_or_create_by!(name: attrs[:org_name]) do |o|
      o.kind = attrs[:org_kind]
      o.status = "pending"
      o.city = attrs[:city]
      o.country = attrs[:country]
      o.country_code = attrs[:country_code]
    end

    temp_pw = SecureRandom.hex(16)
    User.find_or_initialize_by(email: attrs[:email]).tap do |u|
      u.organization = org
      u.name = attrs[:user_name]
      u.role = attrs[:role]
      u.locale = "es"
      u.status = attrs[:status]
      u.password = temp_pw if u.new_record?
      u.save!
    end

    unless Invitation.exists?(email: attrs[:email])
      Invitation.create!(
        email: attrs[:email],
        role: attrs[:role],
        organization: org,
        invited_by: office_user,
        created_at: attrs[:days_ago].days.ago,
        expires_at: (7 - attrs[:days_ago]).days.from_now
      )
    end
  end
end

# --- Pending hotel with COMPLETE onboarding (for admin approval testing) ------
# This hotel was invited by admin, completed its 4-step onboarding,
# and is now pending admin review/approval.
pending_hotel_org = Organization.find_or_create_by!(name: "Alma Verde Wellness") do |o|
  o.kind = "hotel"
  o.status = "pending"
  o.city = "San José"
  o.country = "Costa Rica"
  o.country_code = "CR"
  o.contact_email = "info@almaverde.cr"
  o.website = "https://almaverde.cr"
  o.onboarding_completed_at = 2.days.ago
end
# Ensure onboarding_completed_at is set even if org already exists
pending_hotel_org.update!(onboarding_completed_at: 2.days.ago) unless pending_hotel_org.onboarding_completed?

pending_hotel_user = User.find_or_initialize_by(email: "hotel@almaverde.cr").tap do |u|
  u.organization = pending_hotel_org
  u.name = "Sofía Montero"
  u.role = "owner"
  u.locale = "es"
  u.status = "pending"
  u.password = "humana1234" if u.new_record?
  u.save!
end

pending_hotel = Hotel.find_or_create_by!(organization: pending_hotel_org, name: "Alma Verde Retreat Center") do |h|
  h.city = "San José"
  h.country = "Costa Rica"
  h.country_code = "CR"
  h.latitude = 9.9281
  h.longitude = -84.0907
  h.description = "A boutique wellness center nestled in the cloud forests of Costa Rica. " \
                  "Specializing in plant medicine, breathwork, and holistic nutrition programs " \
                  "with panoramic views of the Central Valley."
  h.address = "Calle Los Helechos 42, Escazú"
  h.wellness_standard = "Global Wellness Institute"
  h.certified = true
  h.stars = 4
  h.total_rooms = 18
  h.phone = "+506 2201 4567"
  h.check_in_time = "15:00"
  h.check_out_time = "11:00"
  h.onboarding_completed_at = 2.days.ago
end
pending_hotel.update!(onboarding_completed_at: 2.days.ago) unless pending_hotel.onboarding_completed?

# Room types
if pending_hotel.room_types.empty?
  [
    { name: "Forest Room", category: "standard", capacity: 2, area_sqm: 26,
      price_per_night_cents: 15000, position: 0,
      description: "Cozy room with floor-to-ceiling windows overlooking the cloud forest canopy." },
    { name: "Valley Suite", category: "suite", capacity: 2, area_sqm: 42,
      price_per_night_cents: 28000, position: 1,
      description: "Spacious suite with private balcony, outdoor shower, and Central Valley views." },
    { name: "Canopy Villa", category: "villa", capacity: 4, area_sqm: 78,
      price_per_night_cents: 48000, position: 2,
      description: "Two-bedroom villa with private plunge pool surrounded by tropical gardens." }
  ].each do |attrs|
    pending_hotel.room_types.create!(attrs.merge(currency: "USD"))
  end
end

# Amenities
if pending_hotel.hotel_amenities.empty?
  [
    { name: "Yoga Shala", category: "wellness", position: 0, featured: true },
    { name: "Meditation Garden", category: "wellness", position: 1, featured: true },
    { name: "Infinity Pool", category: "facilities", position: 2, featured: true },
    { name: "Organic Restaurant", category: "dining", position: 3, featured: true },
    { name: "Spa & Massage", category: "wellness", position: 4, featured: false },
    { name: "Herbal Steam Room", category: "wellness", position: 5, featured: false },
    { name: "Library", category: "facilities", position: 6, featured: false },
    { name: "Free Wi-Fi", category: "facilities", position: 7, featured: false },
  ].each do |attrs|
    pending_hotel.hotel_amenities.create!(attrs)
  end
end

# Create invitation from admin
unless Invitation.exists?(email: "hotel@almaverde.cr")
  Invitation.create!(
    email: "hotel@almaverde.cr",
    role: "owner",
    organization: pending_hotel_org,
    invited_by: admin_user,
    created_at: 5.days.ago,
    expires_at: 2.days.from_now,
    accepted_at: 4.days.ago
  )
end

puts "Done."
puts "  Organizations: #{Organization.count}"
puts "  Users:         #{User.count}"
puts "  Hotels:        #{Hotel.count}"
puts "  Experiences:   #{Experience.count}"
puts "  Clients:       #{Client.count}"
puts "  Bookings:      #{Booking.count}"
puts "  Countries:     #{Country.count}"
puts "  Room Types:    #{RoomType.count}"
puts "  Retreats:      #{Retreat.count}"
puts "  Sub Plans:     #{SubscriptionPlan.count}"
puts "  Subscriptions: #{Subscription.count}"
puts "  Invitations:   #{Invitation.count}"
puts ""
puts "Login credentials:"
puts "  admin@humana.global   / humana1234  (Platform Admin)"
puts "  agent@viajeseter.com  / humana1234  (Agency Owner)"
puts "  hotel@casadelfaro.com / humana1234  (Hotel Owner)"
puts "  office@humana.global  / humana1234  (Office Manager)"
