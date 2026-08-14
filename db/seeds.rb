# HUMANA seed data — platform essentials only.
# Hotels, agencies, and demo data are created through the app.
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

[
  { name: "Agency Monthly", price_cents: 200_000, billing_interval: "monthly",
    commission_rate: 0.16, trial_days: 14, position: 0,
    target_audience: "agency",
    features: { max_bookings: -1, max_clients: -1, support: "priority", analytics: "advanced" } },
  { name: "Agency Annual", price_cents: 1_500_000, billing_interval: "yearly",
    commission_rate: 0.16, trial_days: 14, position: 1,
    target_audience: "agency",
    features: { max_bookings: -1, max_clients: -1, support: "priority", analytics: "advanced" } },
  { name: "Hotel Monthly", price_cents: 300_000, billing_interval: "monthly",
    commission_rate: 0.16, trial_days: 14, position: 0,
    target_audience: "hotel",
    features: { unlimited_room_types: true, retreat_creation: true, analytics: true, support: "priority" } },
  { name: "Hotel Annual", price_cents: 2_500_000, billing_interval: "yearly",
    commission_rate: 0.16, trial_days: 14, position: 1,
    target_audience: "hotel",
    features: { unlimited_room_types: true, retreat_creation: true, analytics: true, support: "priority" } },
].each do |attrs|
  plan = SubscriptionPlan.find_or_initialize_by(name: attrs[:name])
  plan.assign_attributes(attrs)
  plan.currency = "USD"
  plan.active = true
  plan.save!
end

# --- Stripe Products + Prices (sandbox) ----------------------------------------
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

# --- Demo data ---------------------------------------------------------------
# Only created in development / when no hotels exist yet.
if Rails.env.development? || Hotel.count.zero?
  puts "Seeding demo data..."

  # — Office org (HUMANA España) —
  office_org = Organization.find_or_create_by!(name: "HUMANA España") do |o|
    o.kind = "office"
    o.status = "verified"
    o.city = "Madrid"
    o.country = "España"
    o.country_code = "ES"
    o.contact_email = "spain@humana.global"
  end

  User.find_or_initialize_by(email: "office@humana.global").tap do |u|
    u.organization = office_org
    u.name = "María García"
    u.role = "owner"
    u.locale = "es"
    u.status = "active"
    u.password = "humana1234" if u.new_record?
    u.save!
  end

  # — Agency org (Viajes Éter) —
  agency_org = Organization.find_or_create_by!(name: "Viajes Éter") do |o|
    o.kind = "agency"
    o.status = "verified"
    o.city = "Buenos Aires"
    o.country = "Argentina"
    o.country_code = "AR"
    o.contact_email = "info@viajeseter.com"
    o.onboarding_completed_at = Time.current
  end

  agent = User.find_or_initialize_by(email: "agent@viajeseter.com").tap do |u|
    u.organization = agency_org
    u.name = "Lucía Fernández"
    u.role = "owner"
    u.locale = "es"
    u.status = "active"
    u.password = "humana1234" if u.new_record?
    u.onboarding_completed_at = Time.current
    u.save!
  end

  # — Hotel 1: Shanti Wellness Resort (España) —
  hotel1_org = Organization.find_or_create_by!(name: "Shanti Wellness Resort") do |o|
    o.kind = "hotel"
    o.status = "verified"
    o.city = "Ibiza"
    o.country = "España"
    o.country_code = "ES"
    o.contact_email = "info@shantiretreat.com"
    o.onboarding_completed_at = Time.current
  end

  User.find_or_initialize_by(email: "hotel@shantiretreat.com").tap do |u|
    u.organization = hotel1_org
    u.name = "Carlos Mendoza"
    u.role = "owner"
    u.locale = "es"
    u.status = "active"
    u.password = "humana1234" if u.new_record?
    u.onboarding_completed_at = Time.current
    u.save!
  end

  hotel1 = Hotel.find_or_create_by!(name: "Shanti Wellness Resort") do |h|
    h.organization = hotel1_org
    h.city = "Ibiza"
    h.country = "España"
    h.country_code = "ES"
    h.address = "Camino de Sa Caleta 12"
    h.postal_code = "07830"
    h.latitude = 38.8806
    h.longitude = 1.4076
    h.stars = 5
    h.total_rooms = 24
    h.certified = true
    h.wellness_standard = "premium"
    h.description = "Un santuario de bienestar en el corazón de Ibiza, rodeado de naturaleza mediterránea. Nuestro resort ofrece programas de wellness integrales que combinan yoga, meditación, nutrición consciente y terapias holísticas."
    h.check_in_time = "15:00"
    h.check_out_time = "11:00"
    h.phone = "+34 971 123 456"
    h.contact_email = "info@shantiretreat.com"
    h.website = "https://shantiretreat.com"
    h.onboarding_completed_at = Time.current
    h.logo_url = "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=200&h=200&fit=crop"
  end

  # Hotel 1 amenities
  [
    { name: "Infinity Pool", category: "wellness", icon: "pool", position: 0, featured: true },
    { name: "Spa & Hammam", category: "wellness", icon: "spa", position: 1, featured: true },
    { name: "Yoga Shala", category: "wellness", icon: "yoga", position: 2, featured: true },
    { name: "Organic Restaurant", category: "dining", icon: "restaurant", position: 3, featured: true },
    { name: "Meditation Garden", category: "wellness", icon: "meditation", position: 4 },
    { name: "Free Wi-Fi", category: "facilities", icon: "wifi", position: 5 },
    { name: "EV Charging", category: "sustainability", icon: "ev_charging", position: 6 },
    { name: "Airport Transfer", category: "services", icon: "transfer", position: 7 },
  ].each do |attrs|
    hotel1.hotel_amenities.find_or_create_by!(name: attrs[:name]) do |a|
      a.assign_attributes(attrs)
    end
  end

  # Hotel 1 images
  [
    { image_url: "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=1200&q=80", category: "exterior", position: 0, is_cover: true },
    { image_url: "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=1200&q=80", category: "pool", position: 1 },
    { image_url: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&q=80", category: "lobby", position: 2 },
    { image_url: "https://images.unsplash.com/photo-1540555700478-4be289fbec6d?w=1200&q=80", category: "spa", position: 3 },
    { image_url: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=1200&q=80", category: "restaurant", position: 4 },
  ].each do |attrs|
    hotel1.hotel_images.find_or_create_by!(image_url: attrs[:image_url]) do |i|
      i.assign_attributes(attrs)
    end
  end

  # Hotel 1 room types
  suite = hotel1.room_types.find_or_create_by!(name: "Ocean View Suite") do |rt|
    rt.category = "suite"
    rt.capacity = 2
    rt.area_sqm = 55
    rt.price_per_night_cents = 35000
    rt.bed_type = "king"
    rt.view_type = "ocean"
    rt.description = "Suite espaciosa con terraza privada y vista panorámica al mar Mediterráneo. Incluye sala de estar, minibar y amenities orgánicos."
    rt.amenities = %w[air_conditioning private_terrace king_bed minibar safe_box outdoor_shower organic_toiletries free_wifi smart_tv ocean_view]
    rt.status = "active"
    rt.currency = "USD"
  end

  deluxe = hotel1.room_types.find_or_create_by!(name: "Garden Deluxe") do |rt|
    rt.category = "superior"
    rt.capacity = 2
    rt.area_sqm = 38
    rt.price_per_night_cents = 22000
    rt.bed_type = "queen"
    rt.view_type = "garden"
    rt.description = "Habitación deluxe con acceso directo al jardín de meditación. Decoración balinesa y baño con ducha de lluvia."
    rt.amenities = %w[air_conditioning garden_view queen_bed rainfall_shower organic_toiletries free_wifi closet desk]
    rt.status = "active"
    rt.currency = "USD"
  end

  villa = hotel1.room_types.find_or_create_by!(name: "Private Villa") do |rt|
    rt.category = "villa"
    rt.capacity = 4
    rt.area_sqm = 90
    rt.price_per_night_cents = 58000
    rt.bed_type = "king"
    rt.view_type = "ocean"
    rt.description = "Villa privada con piscina plunge, jardín propio y dos habitaciones. La experiencia más exclusiva del resort."
    rt.amenities = %w[air_conditioning private_terrace king_bed minibar safe_box private_plunge_pool outdoor_shower organic_toiletries bathtub free_wifi smart_tv bluetooth_speaker ocean_view hammock]
    rt.status = "active"
    rt.currency = "USD"
  end

  # — Hotel 2: Casa Cenote (México) —
  hotel2_org = Organization.find_or_create_by!(name: "Casa Cenote Tulum") do |o|
    o.kind = "hotel"
    o.status = "verified"
    o.city = "Tulum"
    o.country = "México"
    o.country_code = "MX"
    o.contact_email = "info@casacenote.com"
    o.onboarding_completed_at = Time.current
  end

  User.find_or_initialize_by(email: "hotel@casacenote.com").tap do |u|
    u.organization = hotel2_org
    u.name = "Ana Morales"
    u.role = "owner"
    u.locale = "es"
    u.status = "active"
    u.password = "humana1234" if u.new_record?
    u.onboarding_completed_at = Time.current
    u.save!
  end

  hotel2 = Hotel.find_or_create_by!(name: "Casa Cenote Tulum") do |h|
    h.organization = hotel2_org
    h.city = "Tulum"
    h.country = "México"
    h.country_code = "MX"
    h.address = "Carretera Tulum-Boca Paila km 7.5"
    h.postal_code = "77780"
    h.latitude = 20.2115
    h.longitude = -87.4291
    h.stars = 4
    h.total_rooms = 16
    h.certified = true
    h.wellness_standard = "holistic"
    h.description = "Boutique eco-hotel junto al cenote sagrado de Tulum. Arquitectura maya contemporánea, cocina de raíz y ceremonias ancestrales. Un puente entre la sabiduría ancestral y el bienestar moderno."
    h.check_in_time = "14:00"
    h.check_out_time = "12:00"
    h.phone = "+52 984 871 2345"
    h.contact_email = "info@casacenote.com"
    h.website = "https://casacenote.com"
    h.onboarding_completed_at = Time.current
    h.logo_url = "https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?w=200&h=200&fit=crop"
  end

  # Hotel 2 amenities
  [
    { name: "Cenote Privado", category: "wellness", icon: "pool", position: 0, featured: true },
    { name: "Temazcal", category: "wellness", icon: "spa", position: 1, featured: true },
    { name: "Yoga Deck", category: "wellness", icon: "yoga", position: 2, featured: true },
    { name: "Farm-to-Table Restaurant", category: "dining", icon: "restaurant", position: 3, featured: true },
    { name: "Free Wi-Fi", category: "facilities", icon: "wifi", position: 4 },
    { name: "Bicycle Rental", category: "services", icon: "bicycle", position: 5 },
  ].each do |attrs|
    hotel2.hotel_amenities.find_or_create_by!(name: attrs[:name]) do |a|
      a.assign_attributes(attrs)
    end
  end

  # Hotel 2 images
  [
    { image_url: "https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?w=1200&q=80", category: "exterior", position: 0, is_cover: true },
    { image_url: "https://images.unsplash.com/photo-1615571022219-eb45cf7faa36?w=1200&q=80", category: "pool", position: 1 },
    { image_url: "https://images.unsplash.com/photo-1559599238-308793637427?w=1200&q=80", category: "room", position: 2 },
    { image_url: "https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=1200&q=80", category: "spa", position: 3 },
  ].each do |attrs|
    hotel2.hotel_images.find_or_create_by!(image_url: attrs[:image_url]) do |i|
      i.assign_attributes(attrs)
    end
  end

  # Hotel 2 room types
  jungle_suite = hotel2.room_types.find_or_create_by!(name: "Jungle Suite") do |rt|
    rt.category = "suite"
    rt.capacity = 2
    rt.area_sqm = 45
    rt.price_per_night_cents = 28000
    rt.bed_type = "king"
    rt.view_type = "garden"
    rt.description = "Suite elevada entre la selva maya con techo de palapa y terraza con hamaca. Baño abierto con ducha de lluvia rodeada de vegetación tropical."
    rt.amenities = %w[air_conditioning hammock king_bed rainfall_shower organic_toiletries free_wifi garden_view]
    rt.status = "active"
    rt.currency = "USD"
  end

  cenote_room = hotel2.room_types.find_or_create_by!(name: "Cenote Room") do |rt|
    rt.category = "standard"
    rt.capacity = 2
    rt.area_sqm = 30
    rt.price_per_night_cents = 18000
    rt.bed_type = "queen"
    rt.view_type = "garden"
    rt.description = "Habitación acogedora con acceso directo al cenote privado. Diseño minimalista inspirado en la arquitectura maya."
    rt.amenities = %w[air_conditioning pool_access rainfall_shower organic_toiletries free_wifi]
    rt.status = "active"
    rt.currency = "USD"
  end

  # — Retreat 1: Wellness retreat at Shanti (España) —
  retreat1 = Retreat.find_or_initialize_by(name: "Despertar Interior: Retiro de Yoga & Meditación")
  retreat1.assign_attributes(
    hotel: hotel1,
    created_by_organization: hotel1_org,
    created_by_type: "hotel",
    retreat_type: "wellness",
    status: "active",
    duration_nights: 5,
    starts_on: Date.today + 30,
    ends_on: Date.today + 35,
    capacity: 16,
    language: "es",
    description: "Un retiro transformador de 5 noches en la costa de Ibiza. Programa intensivo de yoga (Vinyasa & Yin), sesiones de meditación guiada, breathwork, caminatas conscientes por la naturaleza mediterránea y talleres de nutrición consciente. Incluye alojamiento, comidas orgánicas y todas las actividades.",
    short_description: "Retiro de yoga, meditación y breathwork en la costa de Ibiza con programa completo de bienestar.",
    location: "Ibiza, España",
    country: "España",
    country_code: "ES",
    currency: "USD",
    commission_rate: 0.16,
    featured: true,
    certified: true,
    published_at: Time.current
  )
  retreat1.save!

  # Retreat 1 images
  [
    { image_url: "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=1200&q=80", position: 0, is_cover: true },
    { image_url: "https://images.unsplash.com/photo-1545205597-3d9d02c29597?w=1200&q=80", position: 1 },
    { image_url: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=1200&q=80", position: 2 },
    { image_url: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=1200&q=80", position: 3 },
  ].each do |attrs|
    retreat1.retreat_images.find_or_create_by!(image_url: attrs[:image_url]) do |i|
      i.assign_attributes(attrs)
    end
  end

  # Retreat 1 facilitators
  retreat1.retreat_facilitators.find_or_create_by!(name: "Elena Ruiz") do |f|
    f.role = "lead"
    f.specialty = "Vinyasa & Yin Yoga"
    f.bio = "Instructora certificada con 15 años de experiencia. Formada en Rishikesh, India. Especialista en yoga restaurativo y meditación mindfulness."
    f.position = 0
  end

  retreat1.retreat_facilitators.find_or_create_by!(name: "Dr. Miguel Santos") do |f|
    f.role = "assistant"
    f.specialty = "Breathwork & Meditación"
    f.bio = "Médico y facilitador de respiración holotrópica. Combina neurociencia y prácticas contemplativas para sesiones de transformación profunda."
    f.position = 1
  end

  # Retreat 1 inclusions
  [
    { name: "5 noches de alojamiento", category: "general", position: 0 },
    { name: "Pensión completa orgánica", category: "meal", position: 1 },
    { name: "2 sesiones de yoga diarias", category: "wellness", position: 2 },
    { name: "Meditación guiada matutina", category: "wellness", position: 3 },
    { name: "1 sesión de breathwork", category: "wellness", position: 4 },
    { name: "Acceso al spa & hammam", category: "amenity", position: 5 },
    { name: "Caminata consciente guiada", category: "activity", position: 6 },
    { name: "Transfer aeropuerto", category: "transport", position: 7 },
    { name: "Kit de bienvenida", category: "general", position: 8 },
  ].each do |attrs|
    retreat1.retreat_inclusions.find_or_create_by!(name: attrs[:name]) do |i|
      i.assign_attributes(attrs)
    end
  end

  # Retreat 1 days & activities
  [
    { day_number: 1, title: "Llegada & Apertura", activities: [
      { name: "Check-in y bienvenida", time: "15:00", duration_minutes: 60, category: "ceremony", position: 0 },
      { name: "Yoga suave de apertura", time: "17:00", duration_minutes: 75, category: "yoga", position: 1 },
      { name: "Cena de bienvenida", time: "19:30", duration_minutes: 90, category: "meal", position: 2 },
      { name: "Círculo de intenciones", time: "21:00", duration_minutes: 45, category: "ceremony", position: 3 },
    ]},
    { day_number: 2, title: "Despertar del Cuerpo", activities: [
      { name: "Meditación del amanecer", time: "07:00", duration_minutes: 30, category: "meditation", position: 0 },
      { name: "Vinyasa Flow", time: "07:45", duration_minutes: 90, category: "yoga", position: 1 },
      { name: "Desayuno orgánico", time: "09:30", duration_minutes: 60, category: "meal", position: 2 },
      { name: "Taller de nutrición consciente", time: "11:00", duration_minutes: 60, category: "workshop", position: 3 },
      { name: "Tiempo libre & Spa", time: "12:30", duration_minutes: 120, category: "free_time", position: 4 },
      { name: "Almuerzo", time: "14:30", duration_minutes: 60, category: "meal", position: 5 },
      { name: "Yin Yoga restaurativo", time: "17:00", duration_minutes: 75, category: "yoga", position: 6 },
      { name: "Cena", time: "19:30", duration_minutes: 90, category: "meal", position: 7 },
    ]},
    { day_number: 3, title: "Respiración & Soltar", activities: [
      { name: "Meditación caminando", time: "07:00", duration_minutes: 45, category: "meditation", position: 0 },
      { name: "Vinyasa Flow", time: "08:00", duration_minutes: 90, category: "yoga", position: 1 },
      { name: "Desayuno", time: "09:45", duration_minutes: 60, category: "meal", position: 2 },
      { name: "Sesión de Breathwork", time: "11:00", duration_minutes: 90, category: "breathwork", position: 3 },
      { name: "Tiempo libre", time: "13:00", duration_minutes: 90, category: "free_time", position: 4 },
      { name: "Almuerzo", time: "14:30", duration_minutes: 60, category: "meal", position: 5 },
      { name: "Caminata consciente por la costa", time: "16:30", duration_minutes: 90, category: "excursion", position: 6 },
      { name: "Yin Yoga & Nidra", time: "18:30", duration_minutes: 75, category: "yoga", position: 7 },
      { name: "Cena", time: "20:00", duration_minutes: 90, category: "meal", position: 8 },
    ]},
    { day_number: 4, title: "Integración", activities: [
      { name: "Meditación silenciosa", time: "07:00", duration_minutes: 30, category: "meditation", position: 0 },
      { name: "Vinyasa Flow", time: "07:45", duration_minutes: 90, category: "yoga", position: 1 },
      { name: "Desayuno", time: "09:30", duration_minutes: 60, category: "meal", position: 2 },
      { name: "Taller de journaling", time: "11:00", duration_minutes: 60, category: "workshop", position: 3 },
      { name: "Hammam & masaje", time: "12:30", duration_minutes: 120, category: "free_time", position: 4 },
      { name: "Almuerzo", time: "14:30", duration_minutes: 60, category: "meal", position: 5 },
      { name: "Yin Yoga profundo", time: "17:00", duration_minutes: 75, category: "yoga", position: 6 },
      { name: "Cena de cierre", time: "19:30", duration_minutes: 120, category: "meal", position: 7 },
    ]},
    { day_number: 5, title: "Cierre & Despedida", activities: [
      { name: "Meditación de gratitud", time: "07:00", duration_minutes: 30, category: "meditation", position: 0 },
      { name: "Yoga de cierre", time: "07:45", duration_minutes: 60, category: "yoga", position: 1 },
      { name: "Desayuno", time: "09:00", duration_minutes: 60, category: "meal", position: 2 },
      { name: "Círculo de cierre", time: "10:30", duration_minutes: 45, category: "ceremony", position: 3 },
      { name: "Check-out", time: "11:30", duration_minutes: 30, category: "ceremony", position: 4 },
    ]},
  ].each do |day_data|
    day = retreat1.retreat_days.find_or_create_by!(day_number: day_data[:day_number]) do |d|
      d.title = day_data[:title]
    end
    day_data[:activities].each do |act_attrs|
      day.retreat_activities.find_or_create_by!(name: act_attrs[:name]) do |a|
        a.assign_attributes(act_attrs)
      end
    end
  end

  # Retreat 1 pricing
  retreat1.retreat_pricings.find_or_create_by!(room_type: deluxe) do |p|
    p.price_per_guest_cents = 110000
    p.occupancy_label = "Ocupación doble"
    p.max_guests = 2
  end
  retreat1.retreat_pricings.find_or_create_by!(room_type: suite) do |p|
    p.price_per_guest_cents = 175000
    p.occupancy_label = "Ocupación doble"
    p.max_guests = 2
  end
  retreat1.retreat_pricings.find_or_create_by!(room_type: villa) do |p|
    p.price_per_guest_cents = 290000
    p.occupancy_label = "Hasta 4 huéspedes"
    p.max_guests = 4
  end
  retreat1.save! # trigger compute_min_price

  # — Retreat 2: Spiritual retreat at Casa Cenote (México) —
  retreat2 = Retreat.find_or_initialize_by(name: "Renacimiento Maya: Ceremonias & Constelaciones")
  retreat2.assign_attributes(
    hotel: hotel2,
    created_by_organization: hotel2_org,
    created_by_type: "hotel",
    retreat_type: "spiritual",
    status: "active",
    duration_nights: 4,
    starts_on: Date.today + 45,
    ends_on: Date.today + 49,
    capacity: 12,
    language: "es",
    description: "Un viaje profundo de 4 noches en el corazón de la selva maya. Ceremonias de cacao, constelaciones familiares, temazcal, meditación en cenote sagrado y reconexión con la sabiduría ancestral. Grupos reducidos para una experiencia íntima y transformadora.",
    short_description: "Ceremonias ancestrales, constelaciones familiares y temazcal en la selva de Tulum.",
    location: "Tulum, México",
    country: "México",
    country_code: "MX",
    currency: "USD",
    commission_rate: 0.16,
    featured: true,
    certified: true,
    published_at: Time.current
  )
  retreat2.save!

  # Retreat 2 images
  [
    { image_url: "https://images.unsplash.com/photo-1559599238-308793637427?w=1200&q=80", position: 0, is_cover: true },
    { image_url: "https://images.unsplash.com/photo-1615571022219-eb45cf7faa36?w=1200&q=80", position: 1 },
    { image_url: "https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=1200&q=80", position: 2 },
  ].each do |attrs|
    retreat2.retreat_images.find_or_create_by!(image_url: attrs[:image_url]) do |i|
      i.assign_attributes(attrs)
    end
  end

  # Retreat 2 facilitators
  retreat2.retreat_facilitators.find_or_create_by!(name: "Abuela Ixchel") do |f|
    f.role = "lead"
    f.specialty = "Ceremonias Ancestrales & Temazcal"
    f.bio = "Guardiana de la tradición maya con 30 años guiando ceremonias de cacao, temazcal y rituales de paso. Su presencia amorosa y sabiduría ancestral crean un espacio sagrado para la transformación."
    f.position = 0
  end

  retreat2.retreat_facilitators.find_or_create_by!(name: "Roberto Vega") do |f|
    f.role = "assistant"
    f.specialty = "Constelaciones Familiares"
    f.bio = "Facilitador certificado por el instituto Hellinger con 12 años de práctica. Integra el enfoque sistémico con la cosmovisión mesoamericana."
    f.position = 1
  end

  # Retreat 2 inclusions
  [
    { name: "4 noches de alojamiento", category: "general", position: 0 },
    { name: "Alimentación completa orgánica", category: "meal", position: 1 },
    { name: "Ceremonia de cacao", category: "wellness", position: 2 },
    { name: "Sesión de temazcal", category: "wellness", position: 3 },
    { name: "Taller de constelaciones familiares", category: "wellness", position: 4 },
    { name: "Meditación en cenote", category: "wellness", position: 5 },
    { name: "Acceso a bicicletas", category: "amenity", position: 6 },
    { name: "Transfer Cancún-Tulum", category: "transport", position: 7 },
  ].each do |attrs|
    retreat2.retreat_inclusions.find_or_create_by!(name: attrs[:name]) do |i|
      i.assign_attributes(attrs)
    end
  end

  # Retreat 2 days & activities
  [
    { day_number: 1, title: "Llegada & Conexión con la Tierra", activities: [
      { name: "Check-in y bienvenida maya", time: "14:00", duration_minutes: 60, category: "ceremony", position: 0 },
      { name: "Meditación en el cenote", time: "16:00", duration_minutes: 45, category: "meditation", position: 1 },
      { name: "Cena ceremonial", time: "19:00", duration_minutes: 90, category: "meal", position: 2 },
      { name: "Ceremonia de cacao", time: "21:00", duration_minutes: 90, category: "ceremony", position: 3 },
    ]},
    { day_number: 2, title: "Constelaciones & Sanación", activities: [
      { name: "Yoga al amanecer", time: "06:30", duration_minutes: 60, category: "yoga", position: 0 },
      { name: "Desayuno", time: "08:00", duration_minutes: 60, category: "meal", position: 1 },
      { name: "Constelaciones familiares (parte 1)", time: "09:30", duration_minutes: 150, category: "workshop", position: 2 },
      { name: "Almuerzo orgánico", time: "13:00", duration_minutes: 60, category: "meal", position: 3 },
      { name: "Tiempo libre & cenote", time: "14:30", duration_minutes: 120, category: "free_time", position: 4 },
      { name: "Constelaciones familiares (parte 2)", time: "17:00", duration_minutes: 120, category: "workshop", position: 5 },
      { name: "Cena", time: "19:30", duration_minutes: 90, category: "meal", position: 6 },
    ]},
    { day_number: 3, title: "Temazcal & Renacimiento", activities: [
      { name: "Meditación caminando en la selva", time: "06:30", duration_minutes: 45, category: "meditation", position: 0 },
      { name: "Desayuno", time: "08:00", duration_minutes: 60, category: "meal", position: 1 },
      { name: "Preparación para temazcal", time: "09:30", duration_minutes: 60, category: "ceremony", position: 2 },
      { name: "Ceremonia de temazcal", time: "11:00", duration_minutes: 150, category: "ceremony", position: 3 },
      { name: "Almuerzo de integración", time: "14:00", duration_minutes: 60, category: "meal", position: 4 },
      { name: "Descanso & integración", time: "15:30", duration_minutes: 120, category: "free_time", position: 5 },
      { name: "Yoga restaurativo", time: "18:00", duration_minutes: 60, category: "yoga", position: 6 },
      { name: "Cena bajo las estrellas", time: "19:30", duration_minutes: 90, category: "meal", position: 7 },
    ]},
    { day_number: 4, title: "Cierre & Nuevo Camino", activities: [
      { name: "Meditación de gratitud", time: "07:00", duration_minutes: 30, category: "meditation", position: 0 },
      { name: "Yoga de cierre", time: "07:45", duration_minutes: 60, category: "yoga", position: 1 },
      { name: "Desayuno", time: "09:00", duration_minutes: 60, category: "meal", position: 2 },
      { name: "Círculo de cierre sagrado", time: "10:30", duration_minutes: 60, category: "ceremony", position: 3 },
      { name: "Check-out", time: "12:00", duration_minutes: 30, category: "ceremony", position: 4 },
    ]},
  ].each do |day_data|
    day = retreat2.retreat_days.find_or_create_by!(day_number: day_data[:day_number]) do |d|
      d.title = day_data[:title]
    end
    day_data[:activities].each do |act_attrs|
      day.retreat_activities.find_or_create_by!(name: act_attrs[:name]) do |a|
        a.assign_attributes(act_attrs)
      end
    end
  end

  # Retreat 2 pricing
  retreat2.retreat_pricings.find_or_create_by!(room_type: cenote_room) do |p|
    p.price_per_guest_cents = 72000
    p.occupancy_label = "Ocupación doble"
    p.max_guests = 2
  end
  retreat2.retreat_pricings.find_or_create_by!(room_type: jungle_suite) do |p|
    p.price_per_guest_cents = 112000
    p.occupancy_label = "Ocupación doble"
    p.max_guests = 2
  end
  retreat2.save! # trigger compute_min_price

  # — Clients for agency —
  Client.find_or_create_by!(email: "sofia@email.com", organization: agency_org) do |c|
    c.name = "Sofía López"
    c.phone = "+54 11 5555 1234"
    c.notes = "Interesada en retiros de yoga. Vegetariana."
  end

  Client.find_or_create_by!(email: "martin@email.com", organization: agency_org) do |c|
    c.name = "Martín Herrera"
    c.phone = "+54 11 5555 5678"
    c.notes = "Busca retiros espirituales para parejas."
  end

  puts "  Demo data created!"
  puts "    Hotels:     #{Hotel.count}"
  puts "    Room types: #{RoomType.count}"
  puts "    Retreats:   #{Retreat.count}"
  puts "    Clients:    #{Client.count}"
end

puts "Done."
puts "  Organizations: #{Organization.count}"
puts "  Users:         #{User.count}"
puts "  Countries:     #{Country.count}"
puts "  Sub Plans:     #{SubscriptionPlan.count}"
puts "  Platform:      #{PlatformSetting.count}"
puts ""
puts "Login credentials:"
puts "  Admin:  admin@humana.global / humana1234"
puts "  Agency: agent@viajeseter.com / humana1234"
puts "  Hotel1: hotel@shantiretreat.com / humana1234"
puts "  Hotel2: hotel@casacenote.com / humana1234"
puts "  Office: office@humana.global / humana1234"
