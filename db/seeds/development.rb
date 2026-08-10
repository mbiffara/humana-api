# Development-only seed data — rich test data for the hotel↔agency flow.
# Loaded from db/seeds.rb when Rails.env.development? is true.

puts ""
puts "Seeding development test data..."

# =============================================================================
# Hotel 1: The House of AïA (Ibiza, Spain)
# =============================================================================
aia_org = Organization.find_or_create_by!(name: "The House of AïA") do |o|
  o.kind = "hotel"
  o.status = "verified"
  o.city = "Ibiza"
  o.country = "España"
  o.country_code = "ES"
  o.contact_email = "hello@houseofaia.com"
  o.website = "https://houseofaia.com"
  o.legal_name = "AïA Wellness SL"
  o.phone = "+34 971 123 456"
  o.tax_id = "B12345678"
  o.description = "A transformative sanctuary in the heart of Ibiza, blending ancient wisdom with modern wellness."
  o.specialties = %w[wellness yoga meditation spiritual]
  o.onboarding_completed_at = Time.current
end

aia_user = User.find_or_initialize_by(email: "hotel@aia.com")
aia_user.assign_attributes(
  organization: aia_org,
  name: "Elena Martínez",
  role: "owner",
  status: "active",
  locale: "en",
  onboarding_completed_at: Time.current
)
aia_user.password = "humana1234" if aia_user.new_record? || !aia_user.authenticate("humana1234")
aia_user.save!

aia_hotel = Hotel.find_or_create_by!(organization: aia_org) do |h|
  h.name = "The House of AïA"
  h.city = "Ibiza"
  h.country = "España"
  h.country_code = "ES"
  h.latitude = 38.9067
  h.longitude = 1.4206
  h.stars = 5
  h.check_in_time = "15:00"
  h.check_out_time = "11:00"
  h.wellness_standard = "Holistic Wellness"
  h.address = "Camino de Sa Vorera 12, Sant Joan de Labritja"
  h.postal_code = "07810"
  h.phone = "+34 971 123 456"
  h.certified = true
  h.description = "A five-star wellness sanctuary nestled in the hills of northern Ibiza. Our property combines traditional Ibizan architecture with cutting-edge wellness facilities."
  h.total_rooms = 15
  h.contact_email = "reservations@houseofaia.com"
  h.website = "https://houseofaia.com"
  h.onboarding_completed_at = Time.current
end

# --- Room Types ---
suite = RoomType.find_or_create_by!(hotel: aia_hotel, name: "Suite Deluxe") do |rt|
  rt.category = "suite"
  rt.capacity = 2
  rt.area_sqm = 45
  rt.price_per_night_cents = 35000
  rt.currency = "EUR"
  rt.description = "Spacious suite with private terrace overlooking the Mediterranean. Features king bed, rain shower, and organic minibar."
  rt.total_rooms = 5
  rt.bed_type = "king"
  rt.view_type = "sea_view"
  rt.amenities = ["Wi-Fi", "Air Conditioning", "Minibar", "Rain Shower", "Private Terrace", "Sea View"]
  rt.position = 0
  rt.status = "active"
end

standard = RoomType.find_or_create_by!(hotel: aia_hotel, name: "Standard Double") do |rt|
  rt.category = "standard"
  rt.capacity = 2
  rt.area_sqm = 28
  rt.price_per_night_cents = 18000
  rt.currency = "EUR"
  rt.description = "Comfortable double room with garden views. Equipped with queen bed and modern en-suite bathroom."
  rt.total_rooms = 8
  rt.bed_type = "queen"
  rt.view_type = "garden_view"
  rt.amenities = ["Wi-Fi", "Air Conditioning", "Garden View", "En-suite Bathroom"]
  rt.position = 1
  rt.status = "active"
end

villa = RoomType.find_or_create_by!(hotel: aia_hotel, name: "Villa Premium") do |rt|
  rt.category = "villa"
  rt.capacity = 4
  rt.area_sqm = 85
  rt.price_per_night_cents = 65000
  rt.currency = "EUR"
  rt.description = "Private villa with plunge pool, two bedrooms, and a fully equipped kitchen. Perfect for families or extended stays."
  rt.total_rooms = 2
  rt.bed_type = "king"
  rt.view_type = "panoramic"
  rt.amenities = ["Wi-Fi", "Air Conditioning", "Private Pool", "Full Kitchen", "Two Bedrooms", "Panoramic View"]
  rt.position = 2
  rt.status = "active"
end

# --- Hotel Amenities ---
amenities_data = [
  { name: "Infinity Pool", category: "wellness", icon: "pool", position: 0, featured: true },
  { name: "Spa & Hammam", category: "wellness", icon: "spa", position: 1, featured: true },
  { name: "Yoga Studio", category: "wellness", icon: "yoga", position: 2, featured: true },
  { name: "Farm-to-Table Restaurant", category: "dining", icon: "restaurant", position: 3, featured: true },
  { name: "Meditation Garden", category: "wellness", icon: "meditation", position: 4, featured: false },
  { name: "Holistic Treatment Room", category: "wellness", icon: "treatment", position: 5, featured: false },
]

amenities_data.each do |attrs|
  HotelAmenity.find_or_create_by!(hotel: aia_hotel, name: attrs[:name]) do |a|
    a.assign_attributes(attrs)
  end
end

# --- Availability Blocks ---
# Partial block: 3 of 5 Suites blocked in Aug 2026
AvailabilityBlock.find_or_create_by!(
  hotel: aia_hotel,
  room_type: suite,
  starts_on: Date.new(2026, 8, 10),
  ends_on: Date.new(2026, 8, 20)
) do |ab|
  ab.units = 3
  ab.reason = "Private group booking"
end

# Total block: Villa closed in Sep 2026
AvailabilityBlock.find_or_create_by!(
  hotel: aia_hotel,
  room_type: villa,
  starts_on: Date.new(2026, 9, 1),
  ends_on: Date.new(2026, 9, 30)
) do |ab|
  ab.units = 2
  ab.reason = "Renovation"
end

# --- Retreat: Transformative Yoga Retreat ---
yoga_retreat = Retreat.find_or_initialize_by(slug: "transformative-yoga-retreat")
yoga_retreat.assign_attributes(
  name: "Transformative Yoga Retreat",
  hotel: aia_hotel,
  created_by_organization: aia_org,
  retreat_type: "wellness",
  status: "active",
  duration_nights: 7,
  starts_on: Date.new(2026, 9, 15),
  ends_on: Date.new(2026, 9, 22),
  capacity: 20,
  language: "en",
  description: "A week-long immersive journey into the depths of yoga and mindfulness. Guided by world-class facilitators in the serene setting of Ibiza's northern hills.",
  short_description: "7-night immersive yoga and mindfulness retreat in Ibiza.",
  location: "Ibiza",
  country: "España",
  country_code: "ES",
  currency: "EUR",
  commission_rate: 0.16,
  featured: true,
  certified: true,
  created_by_type: "hotel",
  published_at: Time.current
)
yoga_retreat.save!

# Retreat Days & Activities
7.times do |i|
  day = RetreatDay.find_or_create_by!(retreat: yoga_retreat, day_number: i + 1) do |d|
    d.title = "Day #{i + 1}"
    d.description = case i
                    when 0 then "Arrival & Opening Circle"
                    when 6 then "Closing Ceremony & Departure"
                    else "Deep Practice & Exploration"
                    end
  end

  activities = case i
               when 0
                 [
                   { name: "Check-in & Welcome Tea", time: "15:00", duration_minutes: 60, position: 0, category: "check_in" },
                   { name: "Opening Circle", time: "17:00", duration_minutes: 90, position: 1, category: "ceremony" },
                   { name: "Welcome Dinner", time: "19:30", duration_minutes: 90, position: 2, category: "meal" },
                 ]
               when 6
                 [
                   { name: "Sunrise Meditation", time: "07:00", duration_minutes: 45, position: 0, category: "meditation" },
                   { name: "Closing Ceremony", time: "09:00", duration_minutes: 120, position: 1, category: "ceremony" },
                   { name: "Farewell Brunch", time: "11:30", duration_minutes: 60, position: 2, category: "meal" },
                 ]
               else
                 [
                   { name: "Morning Vinyasa Flow", time: "07:00", duration_minutes: 90, position: 0, category: "yoga" },
                   { name: "Guided Meditation", time: "09:00", duration_minutes: 45, position: 1, category: "meditation" },
                   { name: "Workshop: #{["Breathwork", "Ayurveda", "Sound Healing", "Yin Yoga", "Journaling"][i - 1]}", time: "11:00", duration_minutes: 120, position: 2, category: "workshop" },
                   { name: "Free Time / Spa", time: "14:00", duration_minutes: 180, position: 3, category: "free_time" },
                   { name: "Restorative Yoga", time: "17:30", duration_minutes: 75, position: 4, category: "yoga" },
                 ]
               end

  activities.each do |act_attrs|
    RetreatActivity.find_or_create_by!(retreat_day: day, name: act_attrs[:name]) do |a|
      a.assign_attributes(act_attrs)
    end
  end
end

# Facilitators
[
  { name: "Priya Sharma", role: "lead", specialty: "Vinyasa & Meditation", bio: "20+ years teaching yoga across India, Bali, and Europe. E-RYT 500 certified.", position: 0 },
  { name: "Marco Bianchi", role: "assistant", specialty: "Breathwork & Sound Healing", bio: "Holistic therapist and breathwork facilitator based in Ibiza. Specializes in transformational sound journeys.", position: 1 },
].each do |f_attrs|
  RetreatFacilitator.find_or_create_by!(retreat: yoga_retreat, name: f_attrs[:name]) do |f|
    f.assign_attributes(f_attrs)
  end
end

# Inclusions
[
  { name: "Daily Yoga & Meditation", category: "wellness", icon: "yoga", position: 0 },
  { name: "Full Board (organic meals)", category: "meal", icon: "restaurant", position: 1 },
  { name: "Airport Transfers", category: "transport", icon: "transfer", position: 2 },
  { name: "1 Spa Treatment", category: "wellness", icon: "spa", position: 3 },
].each do |inc_attrs|
  RetreatInclusion.find_or_create_by!(retreat: yoga_retreat, name: inc_attrs[:name]) do |inc|
    inc.assign_attributes(inc_attrs)
  end
end

# Pricing per room type
[
  { room_type: suite, price_per_guest_cents: 280000, occupancy_label: "Single in Suite", max_guests: 1, currency: "EUR" },
  { room_type: standard, price_per_guest_cents: 180000, occupancy_label: "Single in Standard", max_guests: 1, currency: "EUR" },
  { room_type: villa, price_per_guest_cents: 450000, occupancy_label: "Villa (up to 4)", max_guests: 4, currency: "EUR" },
].each do |p_attrs|
  RetreatPricing.find_or_create_by!(retreat: yoga_retreat, room_type: p_attrs[:room_type]) do |p|
    p.assign_attributes(p_attrs.except(:room_type))
  end
end

# Force min_price recompute
yoga_retreat.save!

# Retreat Images
[
  { image_url: "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=1200", position: 0, is_cover: true, alt_text: "Yoga at sunrise" },
  { image_url: "https://images.unsplash.com/photo-1545205597-3d9d02c29597?w=1200", position: 1, is_cover: false, alt_text: "Meditation garden" },
  { image_url: "https://images.unsplash.com/photo-1600618528240-fb9fc964b853?w=1200", position: 2, is_cover: false, alt_text: "Wellness spa" },
].each do |img_attrs|
  RetreatImage.find_or_create_by!(retreat: yoga_retreat, position: img_attrs[:position]) do |img|
    img.assign_attributes(img_attrs)
  end
end

# --- Experience linked to retreat ---
aia_exp = Experience.find_or_initialize_by(slug: "transformative-yoga-retreat-ibiza")
aia_exp.assign_attributes(
  hotel: aia_hotel,
  kind: "wellness",
  title: "Transformative Yoga Retreat — Ibiza",
  description: yoga_retreat.description,
  location: "Ibiza",
  country: "España",
  country_code: "ES",
  starts_on: yoga_retreat.starts_on,
  ends_on: yoga_retreat.ends_on,
  price_cents: yoga_retreat.min_price_cents,
  currency: "EUR",
  capacity: 20,
  commission_rate: 0.16,
  status: "active",
  image_url: "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800"
)
aia_exp.save!

# =============================================================================
# Agency: Viajes Éter
# =============================================================================
agency_org = Organization.find_or_create_by!(name: "Viajes Éter") do |o|
  o.kind = "agency"
  o.status = "verified"
  o.city = "Barcelona"
  o.country = "España"
  o.country_code = "ES"
  o.contact_email = "info@viajeseter.com"
  o.website = "https://viajeseter.com"
  o.legal_name = "Viajes Éter SL"
  o.phone = "+34 93 456 7890"
  o.description = "Boutique travel agency specializing in wellness and transformative retreats across Europe and Latin America."
  o.specialties = %w[wellness spiritual yoga adventure]
  o.onboarding_completed_at = Time.current
end

agency_user = User.find_or_initialize_by(email: "agent@viajeseter.com")
agency_user.assign_attributes(
  organization: agency_org,
  name: "Sofía Delgado",
  role: "owner",
  status: "active",
  locale: "en",
  onboarding_completed_at: Time.current
)
agency_user.password = "humana1234" if agency_user.new_record? || !agency_user.authenticate("humana1234")
agency_user.save!

# --- Clients ---
maria = Client.find_or_create_by!(organization: agency_org, name: "María González") do |c|
  c.email = "maria.gonzalez@email.com"
  c.phone = "+34 612 345 678"
  c.notes = "Prefers single occupancy. Vegetarian. Interested in yoga and meditation retreats."
end

carlos = Client.find_or_create_by!(organization: agency_org, name: "Carlos Ruiz") do |c|
  c.email = "carlos.ruiz@email.com"
  c.phone = "+34 698 765 432"
  c.notes = "Corporate wellness programs. Budget flexible. Prefers luxury accommodations."
end

Client.find_or_create_by!(organization: agency_org, name: "Ana Martín") do |c|
  c.email = "ana.martin@email.com"
  c.phone = "+34 655 111 222"
  c.notes = "First-time retreat guest. Looking for spiritual experiences."
end

# --- Bookings ---
# Confirmed booking
unless Booking.joins(:experience).where(organization: agency_org, client: maria, experiences: { id: aia_exp.id }, status: "confirmed").exists?
  Booking.create!(
    organization: agency_org,
    experience: aia_exp,
    client: maria,
    room_type: suite,
    guests: 2,
    status: "confirmed",
    starts_on: aia_exp.starts_on,
    ends_on: aia_exp.ends_on,
    notes: "Anniversary trip. Please arrange flowers in room."
  )
end

# Inquiry booking
unless Booking.joins(:experience).where(organization: agency_org, client: carlos, experiences: { id: aia_exp.id }, status: "inquiry").exists?
  Booking.create!(
    organization: agency_org,
    experience: aia_exp,
    client: carlos,
    guests: 1,
    status: "inquiry",
    starts_on: aia_exp.starts_on,
    ends_on: aia_exp.ends_on,
    notes: "Interested in corporate wellness package. May bring 3 more colleagues."
  )
end

# =============================================================================
# Hotel 2: Santuario del Sol (Mexico)
# =============================================================================
sol_org = Organization.find_or_create_by!(name: "Santuario del Sol") do |o|
  o.kind = "hotel"
  o.status = "verified"
  o.city = "Tulum"
  o.country = "México"
  o.country_code = "MX"
  o.contact_email = "info@santuariodelsol.mx"
  o.website = "https://santuariodelsol.mx"
  o.legal_name = "Santuario del Sol SA de CV"
  o.phone = "+52 984 123 4567"
  o.description = "Eco-luxury retreat center on the Riviera Maya, where Mayan traditions meet modern wellness."
  o.specialties = %w[wellness spiritual adventure nature]
  o.onboarding_completed_at = Time.current
end

sol_user = User.find_or_initialize_by(email: "hotel@santuariodelsol.mx")
sol_user.assign_attributes(
  organization: sol_org,
  name: "Diego Hernández",
  role: "owner",
  status: "active",
  locale: "es",
  onboarding_completed_at: Time.current
)
sol_user.password = "humana1234" if sol_user.new_record? || !sol_user.authenticate("humana1234")
sol_user.save!

sol_hotel = Hotel.find_or_create_by!(organization: sol_org) do |h|
  h.name = "Santuario del Sol"
  h.city = "Tulum"
  h.country = "México"
  h.country_code = "MX"
  h.latitude = 20.2114
  h.longitude = -87.4654
  h.stars = 4
  h.check_in_time = "14:00"
  h.check_out_time = "12:00"
  h.wellness_standard = "Eco Wellness"
  h.address = "Carretera Tulum-Boca Paila Km 7.5"
  h.postal_code = "77780"
  h.phone = "+52 984 123 4567"
  h.certified = true
  h.description = "An eco-luxury retreat center set between jungle and ocean. Our temazcal ceremonies and cenote dives offer a unique connection to the land."
  h.total_rooms = 10
  h.contact_email = "reservations@santuariodelsol.mx"
  h.website = "https://santuariodelsol.mx"
  h.onboarding_completed_at = Time.current
end

# Room types
sol_jungle = RoomType.find_or_create_by!(hotel: sol_hotel, name: "Jungle Cabana") do |rt|
  rt.category = "bungalow"
  rt.capacity = 2
  rt.area_sqm = 32
  rt.price_per_night_cents = 22000
  rt.currency = "MXN"
  rt.description = "Open-air cabana surrounded by tropical jungle. Features artisanal furnishings and private outdoor shower."
  rt.total_rooms = 6
  rt.bed_type = "queen"
  rt.view_type = "jungle_view"
  rt.amenities = ["Wi-Fi", "Ceiling Fan", "Outdoor Shower", "Mosquito Net", "Hammock"]
  rt.position = 0
  rt.status = "active"
end

sol_ocean = RoomType.find_or_create_by!(hotel: sol_hotel, name: "Ocean Suite") do |rt|
  rt.category = "suite"
  rt.capacity = 2
  rt.area_sqm = 50
  rt.price_per_night_cents = 45000
  rt.currency = "MXN"
  rt.description = "Beachfront suite with private plunge pool and direct ocean access. Handcrafted Mayan-inspired interiors."
  rt.total_rooms = 4
  rt.bed_type = "king"
  rt.view_type = "ocean_view"
  rt.amenities = ["Wi-Fi", "Air Conditioning", "Plunge Pool", "Ocean View", "Private Terrace", "Minibar"]
  rt.position = 1
  rt.status = "active"
end

# Hotel amenities
[
  { name: "Temazcal (sweat lodge)", category: "wellness", icon: "temazcal", position: 0, featured: true },
  { name: "Cenote Access", category: "recreation", icon: "cenote", position: 1, featured: true },
  { name: "Beach Club", category: "recreation", icon: "beach", position: 2, featured: true },
  { name: "Organic Restaurant", category: "dining", icon: "restaurant", position: 3, featured: true },
].each do |attrs|
  HotelAmenity.find_or_create_by!(hotel: sol_hotel, name: attrs[:name]) do |a|
    a.assign_attributes(attrs)
  end
end

# Retreat
sol_retreat = Retreat.find_or_initialize_by(slug: "mayan-spirit-retreat")
sol_retreat.assign_attributes(
  name: "Mayan Spirit Retreat",
  hotel: sol_hotel,
  created_by_organization: sol_org,
  retreat_type: "spiritual",
  status: "active",
  duration_nights: 5,
  starts_on: Date.new(2026, 10, 5),
  ends_on: Date.new(2026, 10, 10),
  capacity: 16,
  language: "es",
  description: "Reconnect with ancient Mayan wisdom through temazcal ceremonies, cenote rituals, and jungle meditation. A transformative 5-night journey.",
  short_description: "5-night spiritual retreat in Tulum with Mayan ceremonies.",
  location: "Tulum",
  country: "México",
  country_code: "MX",
  currency: "MXN",
  commission_rate: 0.16,
  featured: true,
  certified: true,
  created_by_type: "hotel",
  published_at: Time.current
)
sol_retreat.save!

# Days & activities (simplified)
5.times do |i|
  day = RetreatDay.find_or_create_by!(retreat: sol_retreat, day_number: i + 1) do |d|
    d.title = "Day #{i + 1}"
  end

  activities = [
    { name: "Sunrise Beach Meditation", time: "06:30", duration_minutes: 45, position: 0, category: "meditation" },
    { name: i == 2 ? "Temazcal Ceremony" : "Morning Practice", time: "08:00", duration_minutes: 90, position: 1, category: i == 2 ? "ceremony" : "yoga" },
    { name: "Cenote Dive", time: "11:00", duration_minutes: 120, position: 2, category: "excursion" },
  ]
  activities.each do |act_attrs|
    RetreatActivity.find_or_create_by!(retreat_day: day, name: act_attrs[:name]) do |a|
      a.assign_attributes(act_attrs)
    end
  end
end

# Facilitator
RetreatFacilitator.find_or_create_by!(retreat: sol_retreat, name: "Ixchel Caamal") do |f|
  f.role = "lead"
  f.specialty = "Mayan Ceremonies & Energy Work"
  f.bio = "Born in Valladolid, Ixchel is a keeper of Mayan traditions and certified holistic therapist."
  f.position = 0
end

# Inclusions
[
  { name: "All Ceremonies & Rituals", category: "wellness", icon: "ceremony", position: 0 },
  { name: "Full Board (local cuisine)", category: "meal", icon: "restaurant", position: 1 },
  { name: "Cenote & Beach Access", category: "amenity", icon: "cenote", position: 2 },
].each do |inc_attrs|
  RetreatInclusion.find_or_create_by!(retreat: sol_retreat, name: inc_attrs[:name]) do |inc|
    inc.assign_attributes(inc_attrs)
  end
end

# Pricing
[
  { room_type: sol_jungle, price_per_guest_cents: 3500000, occupancy_label: "Jungle Cabana", max_guests: 2, currency: "MXN" },
  { room_type: sol_ocean, price_per_guest_cents: 5500000, occupancy_label: "Ocean Suite", max_guests: 2, currency: "MXN" },
].each do |p_attrs|
  RetreatPricing.find_or_create_by!(retreat: sol_retreat, room_type: p_attrs[:room_type]) do |p|
    p.assign_attributes(p_attrs.except(:room_type))
  end
end

sol_retreat.save!

# Retreat images
[
  { image_url: "https://images.unsplash.com/photo-1596178060810-72f53ce9a65c?w=1200", position: 0, is_cover: true, alt_text: "Tulum beach at sunrise" },
  { image_url: "https://images.unsplash.com/photo-1570737209810-a6e946f6aef0?w=1200", position: 1, is_cover: false, alt_text: "Jungle cabana" },
].each do |img_attrs|
  RetreatImage.find_or_create_by!(retreat: sol_retreat, position: img_attrs[:position]) do |img|
    img.assign_attributes(img_attrs)
  end
end

# Experience for Santuario del Sol
sol_exp = Experience.find_or_initialize_by(slug: "mayan-spirit-retreat-tulum")
sol_exp.assign_attributes(
  hotel: sol_hotel,
  kind: "spiritual",
  title: "Mayan Spirit Retreat — Tulum",
  description: sol_retreat.description,
  location: "Tulum",
  country: "México",
  country_code: "MX",
  starts_on: sol_retreat.starts_on,
  ends_on: sol_retreat.ends_on,
  price_cents: sol_retreat.min_price_cents,
  currency: "MXN",
  capacity: 16,
  commission_rate: 0.16,
  status: "active",
  image_url: "https://images.unsplash.com/photo-1596178060810-72f53ce9a65c?w=800"
)
sol_exp.save!

# =============================================================================
# Office: HUMANA Spain
# =============================================================================
office_org = Organization.find_or_create_by!(name: "HUMANA Spain") do |o|
  o.kind = "office"
  o.status = "verified"
  o.city = "Madrid"
  o.country = "España"
  o.country_code = "ES"
  o.contact_email = "spain@humana.global"
  o.phone = "+34 91 000 0000"
  o.description = "HUMANA regional office for Spain. Manages hotels and agencies operating in the Spanish market."
  o.onboarding_completed_at = Time.current
end

office_user = User.find_or_initialize_by(email: "office@humana.global")
office_user.assign_attributes(
  organization: office_org,
  name: "Pablo Navarro",
  role: "owner",
  status: "active",
  locale: "en",
  onboarding_completed_at: Time.current
)
office_user.password = "humana1234" if office_user.new_record? || !office_user.authenticate("humana1234")
office_user.save!

# Office team member
office_member = User.find_or_initialize_by(email: "lucia@humana.global")
office_member.assign_attributes(
  organization: office_org,
  name: "Lucía Fernández",
  role: "member",
  status: "active",
  locale: "es",
  onboarding_completed_at: Time.current
)
office_member.password = "humana1234" if office_member.new_record? || !office_member.authenticate("humana1234")
office_member.save!

# =============================================================================
# Additional Spanish Hotels (for richer office data)
# =============================================================================

# Hotel 3: Cal Reiet (Mallorca)
calreiet_org = Organization.find_or_create_by!(name: "Cal Reiet Holistic Retreat") do |o|
  o.kind = "hotel"
  o.status = "verified"
  o.city = "Santanyí"
  o.country = "España"
  o.country_code = "ES"
  o.contact_email = "info@calreiet.com"
  o.website = "https://calreiet.com"
  o.legal_name = "Cal Reiet SL"
  o.phone = "+34 971 647 047"
  o.description = "A holistic sanctuary in rural Mallorca, combining ancient finca charm with modern wellness philosophy."
  o.specialties = %w[wellness yoga meditation detox]
  o.onboarding_completed_at = Time.current
end

calreiet_hotel = Hotel.find_or_create_by!(organization: calreiet_org) do |h|
  h.name = "Cal Reiet Holistic Retreat"
  h.city = "Santanyí"
  h.country = "España"
  h.country_code = "ES"
  h.latitude = 39.3558
  h.longitude = 3.1249
  h.stars = 5
  h.check_in_time = "15:00"
  h.check_out_time = "11:00"
  h.wellness_standard = "Integrative Wellness"
  h.address = "Carrer de Can Reiet 7, Santanyí"
  h.postal_code = "07650"
  h.phone = "+34 971 647 047"
  h.certified = true
  h.description = "A restored 19th-century finca offering transformative wellness experiences amid Mallorca's serene countryside. Our integrative approach combines nutrition, movement, and mindfulness."
  h.total_rooms = 12
  h.contact_email = "reservations@calreiet.com"
  h.website = "https://calreiet.com"
  h.onboarding_completed_at = Time.current
end

calreiet_user = User.find_or_initialize_by(email: "hotel@calreiet.com")
calreiet_user.assign_attributes(organization: calreiet_org, name: "Marta Roca", role: "owner", status: "active", locale: "es", onboarding_completed_at: Time.current)
calreiet_user.password = "humana1234" if calreiet_user.new_record? || !calreiet_user.authenticate("humana1234")
calreiet_user.save!

calreiet_suite = RoomType.find_or_create_by!(hotel: calreiet_hotel, name: "Garden Suite") do |rt|
  rt.category = "suite"
  rt.capacity = 2
  rt.area_sqm = 40
  rt.price_per_night_cents = 32000
  rt.currency = "EUR"
  rt.description = "Elegant garden suite with private terrace overlooking the olive groves."
  rt.total_rooms = 6
  rt.bed_type = "king"
  rt.view_type = "garden_view"
  rt.amenities = ["Wi-Fi", "Air Conditioning", "Minibar", "Private Terrace", "Garden View"]
  rt.position = 0
  rt.status = "active"
end

calreiet_std = RoomType.find_or_create_by!(hotel: calreiet_hotel, name: "Heritage Room") do |rt|
  rt.category = "standard"
  rt.capacity = 2
  rt.area_sqm = 25
  rt.price_per_night_cents = 22000
  rt.currency = "EUR"
  rt.description = "Charming room in the original finca wing with restored stone walls."
  rt.total_rooms = 6
  rt.bed_type = "queen"
  rt.view_type = "courtyard_view"
  rt.amenities = ["Wi-Fi", "Air Conditioning", "En-suite Bathroom", "Courtyard View"]
  rt.position = 1
  rt.status = "active"
end

# Cal Reiet retreat: Detox & Reset (active)
calreiet_retreat = Retreat.find_or_initialize_by(slug: "detox-reset-mallorca")
calreiet_retreat.assign_attributes(
  name: "Detox & Reset Retreat",
  hotel: calreiet_hotel,
  created_by_organization: calreiet_org,
  retreat_type: "wellness",
  status: "active",
  duration_nights: 5,
  starts_on: Date.new(2026, 10, 12),
  ends_on: Date.new(2026, 10, 17),
  capacity: 12,
  language: "en",
  description: "A 5-night cleansing journey in rural Mallorca. Juice fasting, yoga, colon hydrotherapy, and nutritional coaching in a stunning countryside setting.",
  short_description: "5-night detox and renewal retreat in Mallorca.",
  location: "Santanyí",
  country: "España",
  country_code: "ES",
  currency: "EUR",
  commission_rate: 0.16,
  featured: true,
  certified: true,
  created_by_type: "hotel",
  published_at: Time.current
)
calreiet_retreat.save!

5.times do |i|
  day = RetreatDay.find_or_create_by!(retreat: calreiet_retreat, day_number: i + 1) do |d|
    d.title = "Day #{i + 1}"
  end
  activities = [
    { name: "Morning Yoga", time: "07:30", duration_minutes: 75, position: 0, category: "yoga" },
    { name: "Juice & Nutritional Workshop", time: "10:00", duration_minutes: 90, position: 1, category: "workshop" },
    { name: "Guided Nature Walk", time: "16:00", duration_minutes: 60, position: 2, category: "excursion" },
  ]
  activities.each do |act_attrs|
    RetreatActivity.find_or_create_by!(retreat_day: day, name: act_attrs[:name]) do |a|
      a.assign_attributes(act_attrs)
    end
  end
end

RetreatFacilitator.find_or_create_by!(retreat: calreiet_retreat, name: "Dr. Ana Beltrán") do |f|
  f.role = "lead"
  f.specialty = "Integrative Nutrition & Detox"
  f.bio = "Functional medicine doctor specializing in gut health and metabolic reset protocols."
  f.position = 0
end

[
  { name: "All Juices & Cleanse Meals", category: "meal", icon: "restaurant", position: 0 },
  { name: "Daily Yoga & Meditation", category: "wellness", icon: "yoga", position: 1 },
  { name: "1 Colonic Session", category: "wellness", icon: "spa", position: 2 },
].each do |inc_attrs|
  RetreatInclusion.find_or_create_by!(retreat: calreiet_retreat, name: inc_attrs[:name]) do |inc|
    inc.assign_attributes(inc_attrs)
  end
end

[
  { room_type: calreiet_suite, price_per_guest_cents: 310000, occupancy_label: "Garden Suite", max_guests: 1, currency: "EUR" },
  { room_type: calreiet_std, price_per_guest_cents: 220000, occupancy_label: "Heritage Room", max_guests: 1, currency: "EUR" },
].each do |p_attrs|
  RetreatPricing.find_or_create_by!(retreat: calreiet_retreat, room_type: p_attrs[:room_type]) do |p|
    p.assign_attributes(p_attrs.except(:room_type))
  end
end
calreiet_retreat.save!

calreiet_exp = Experience.find_or_initialize_by(slug: "detox-reset-mallorca")
calreiet_exp.assign_attributes(
  hotel: calreiet_hotel, kind: "mindfulness",
  title: "Detox & Reset — Mallorca",
  description: calreiet_retreat.description,
  location: "Santanyí", country: "España", country_code: "ES",
  starts_on: calreiet_retreat.starts_on, ends_on: calreiet_retreat.ends_on,
  price_cents: calreiet_retreat.min_price_cents, currency: "EUR",
  capacity: 12, commission_rate: 0.16, status: "active",
  image_url: "https://images.unsplash.com/photo-1540555700478-4be289fbec6d?w=800"
)
calreiet_exp.save!

# Hotel 4: SHA Wellness (Alicante)
sha_org = Organization.find_or_create_by!(name: "SHA Wellness Clinic") do |o|
  o.kind = "hotel"
  o.status = "verified"
  o.city = "Alicante"
  o.country = "España"
  o.country_code = "ES"
  o.contact_email = "info@shawellnessclinic.com"
  o.website = "https://shawellnessclinic.com"
  o.legal_name = "SHA Wellness Clinic SL"
  o.phone = "+34 966 811 199"
  o.description = "World-leading integrative wellness clinic blending Eastern techniques with Western medicine."
  o.specialties = %w[wellness medical detox anti-aging]
  o.onboarding_completed_at = Time.current
end

sha_hotel = Hotel.find_or_create_by!(organization: sha_org) do |h|
  h.name = "SHA Wellness Clinic"
  h.city = "Alicante"
  h.country = "España"
  h.country_code = "ES"
  h.latitude = 38.6413
  h.longitude = -0.0441
  h.stars = 5
  h.check_in_time = "14:00"
  h.check_out_time = "12:00"
  h.wellness_standard = "Medical Wellness"
  h.address = "Carrer del Verderol 5, El Albir"
  h.postal_code = "03581"
  h.phone = "+34 966 811 199"
  h.certified = true
  h.description = "A world-class medical wellness destination on Spain's Mediterranean coast. Our multidisciplinary team delivers science-based programs for longevity."
  h.total_rooms = 25
  h.contact_email = "reservations@shawellnessclinic.com"
  h.website = "https://shawellnessclinic.com"
  h.onboarding_completed_at = Time.current
end

sha_user = User.find_or_initialize_by(email: "hotel@sha.com")
sha_user.assign_attributes(organization: sha_org, name: "Alejandro Bataller", role: "owner", status: "active", locale: "es", onboarding_completed_at: Time.current)
sha_user.password = "humana1234" if sha_user.new_record? || !sha_user.authenticate("humana1234")
sha_user.save!

sha_suite = RoomType.find_or_create_by!(hotel: sha_hotel, name: "SHA Suite") do |rt|
  rt.category = "suite"
  rt.capacity = 2
  rt.area_sqm = 60
  rt.price_per_night_cents = 55000
  rt.currency = "EUR"
  rt.description = "Luxurious suite with panoramic Mediterranean views and private wellness area."
  rt.total_rooms = 10
  rt.bed_type = "king"
  rt.view_type = "sea_view"
  rt.amenities = ["Wi-Fi", "Air Conditioning", "Private Wellness Area", "Sea View", "Minibar", "Balcony"]
  rt.position = 0
  rt.status = "active"
end

sha_deluxe = RoomType.find_or_create_by!(hotel: sha_hotel, name: "Deluxe Room") do |rt|
  rt.category = "superior"
  rt.capacity = 2
  rt.area_sqm = 38
  rt.price_per_night_cents = 38000
  rt.currency = "EUR"
  rt.description = "Bright and spacious room with mountain or garden views."
  rt.total_rooms = 15
  rt.bed_type = "king"
  rt.view_type = "garden_view"
  rt.amenities = ["Wi-Fi", "Air Conditioning", "Minibar", "En-suite Bathroom"]
  rt.position = 1
  rt.status = "active"
end

# SHA retreat: Longevity (pending_review)
sha_retreat = Retreat.find_or_initialize_by(slug: "longevity-program-sha")
sha_retreat.assign_attributes(
  name: "Longevity Program",
  hotel: sha_hotel,
  created_by_organization: sha_org,
  retreat_type: "neurociencia",
  status: "pending_review",
  duration_nights: 7,
  starts_on: Date.new(2026, 11, 1),
  ends_on: Date.new(2026, 11, 8),
  capacity: 15,
  language: "en",
  description: "A comprehensive 7-night longevity protocol combining genetic testing, IV therapy, and personalized nutrition plans.",
  short_description: "7-night medical longevity program in Alicante.",
  location: "Alicante",
  country: "España",
  country_code: "ES",
  currency: "EUR",
  commission_rate: 0.14,
  featured: false,
  certified: true,
  created_by_type: "hotel"
)
sha_retreat.save!

sha_exp = Experience.find_or_initialize_by(slug: "longevity-program-sha")
sha_exp.assign_attributes(
  hotel: sha_hotel, kind: "neurociencia",
  title: "Longevity Program — SHA Wellness",
  description: sha_retreat.description,
  location: "Alicante", country: "España", country_code: "ES",
  starts_on: sha_retreat.starts_on, ends_on: sha_retreat.ends_on,
  price_cents: 450000, currency: "EUR",
  capacity: 15, commission_rate: 0.14, status: "active",
  image_url: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800"
)
sha_exp.save!

# Hotel 5: Aire de Bardenas (Navarra) — draft status
aire_org = Organization.find_or_create_by!(name: "Aire de Bardenas") do |o|
  o.kind = "hotel"
  o.status = "verified"
  o.city = "Tudela"
  o.country = "España"
  o.country_code = "ES"
  o.contact_email = "info@airedebardenas.com"
  o.website = "https://airedebardenas.com"
  o.legal_name = "Aire de Bardenas SL"
  o.phone = "+34 948 116 666"
  o.description = "Minimalist design hotel at the edge of the Bardenas Reales desert."
  o.specialties = %w[design nature silence]
  o.onboarding_completed_at = Time.current
end

aire_hotel = Hotel.find_or_create_by!(organization: aire_org) do |h|
  h.name = "Aire de Bardenas"
  h.city = "Tudela"
  h.country = "España"
  h.country_code = "ES"
  h.latitude = 42.0658
  h.longitude = -1.6038
  h.stars = 4
  h.check_in_time = "14:00"
  h.check_out_time = "12:00"
  h.wellness_standard = "Nature Wellness"
  h.address = "Ctra. del Parque Natural, Tudela"
  h.postal_code = "31500"
  h.phone = "+34 948 116 666"
  h.certified = false
  h.description = "Award-winning minimalist hotel overlooking the lunar landscape of Bardenas Reales Natural Park."
  h.total_rooms = 8
  h.contact_email = "reservations@airedebardenas.com"
  h.website = "https://airedebardenas.com"
  h.onboarding_completed_at = Time.current
end

aire_user = User.find_or_initialize_by(email: "hotel@airedebardenas.com")
aire_user.assign_attributes(organization: aire_org, name: "Íñigo Azpilicueta", role: "owner", status: "active", locale: "es", onboarding_completed_at: Time.current)
aire_user.password = "humana1234" if aire_user.new_record? || !aire_user.authenticate("humana1234")
aire_user.save!

# Draft retreat (to show in retreats filter)
aire_retreat = Retreat.find_or_initialize_by(slug: "silence-desert-retreat")
aire_retreat.assign_attributes(
  name: "Silence in the Desert",
  hotel: aire_hotel,
  created_by_organization: aire_org,
  retreat_type: "breathwork",
  status: "draft",
  duration_nights: 3,
  starts_on: Date.new(2026, 12, 1),
  ends_on: Date.new(2026, 12, 4),
  capacity: 8,
  language: "es",
  description: "A silent retreat in the surreal Bardenas Reales desert. Three nights of digital detox, walking meditation, and stargazing.",
  short_description: "3-night silent retreat in Bardenas desert.",
  location: "Tudela",
  country: "España",
  country_code: "ES",
  currency: "EUR",
  commission_rate: 0.16,
  featured: false,
  certified: false,
  created_by_type: "hotel"
)
aire_retreat.save!

# =============================================================================
# Additional Spanish Agencies (for richer office network & booking data)
# =============================================================================

# Agency 2: Wellness Travel Co (Madrid)
wellness_co_org = Organization.find_or_create_by!(name: "Wellness Travel Co") do |o|
  o.kind = "agency"
  o.status = "verified"
  o.city = "Madrid"
  o.country = "España"
  o.country_code = "ES"
  o.contact_email = "hello@wellnesstravelco.es"
  o.website = "https://wellnesstravelco.es"
  o.legal_name = "Wellness Travel Co SL"
  o.phone = "+34 91 555 1234"
  o.description = "Premium wellness travel consultancy based in Madrid, connecting clients with the finest retreat experiences."
  o.specialties = %w[wellness luxury corporate]
  o.onboarding_completed_at = Time.current
end

wtc_user = User.find_or_initialize_by(email: "agent@wellnesstravelco.es")
wtc_user.assign_attributes(organization: wellness_co_org, name: "Carmen Iglesias", role: "owner", status: "active", locale: "es", onboarding_completed_at: Time.current)
wtc_user.password = "humana1234" if wtc_user.new_record? || !wtc_user.authenticate("humana1234")
wtc_user.save!

# Agency 3: Retiros Ibéricos (Valencia) — pending status
retiros_org = Organization.find_or_create_by!(name: "Retiros Ibéricos") do |o|
  o.kind = "agency"
  o.status = "pending"
  o.city = "Valencia"
  o.country = "España"
  o.country_code = "ES"
  o.contact_email = "contacto@retirosibericos.es"
  o.legal_name = "Retiros Ibéricos SL"
  o.phone = "+34 96 333 4444"
  o.description = "Agencia especializada en retiros de bienestar por toda la Península Ibérica."
  o.specialties = %w[wellness nature spiritual]
  o.onboarding_completed_at = Time.current
end

ri_user = User.find_or_initialize_by(email: "agent@retirosibericos.es")
ri_user.assign_attributes(organization: retiros_org, name: "Javier Moreno", role: "owner", status: "pending", locale: "es", onboarding_completed_at: Time.current)
ri_user.password = "humana1234" if ri_user.new_record? || !ri_user.authenticate("humana1234")
ri_user.save!

# Agency 4: ZenPath (Bilbao)
zenpath_org = Organization.find_or_create_by!(name: "ZenPath Retreats") do |o|
  o.kind = "agency"
  o.status = "verified"
  o.city = "Bilbao"
  o.country = "España"
  o.country_code = "ES"
  o.contact_email = "hello@zenpath.es"
  o.website = "https://zenpath.es"
  o.legal_name = "ZenPath Travel SL"
  o.phone = "+34 94 411 2233"
  o.description = "Boutique retreat specialists in the Basque Country. Expert curation for discerning travelers."
  o.specialties = %w[wellness yoga nature gourmet]
  o.onboarding_completed_at = Time.current
end

zp_user = User.find_or_initialize_by(email: "agent@zenpath.es")
zp_user.assign_attributes(organization: zenpath_org, name: "Ane Etxebarria", role: "owner", status: "active", locale: "es", onboarding_completed_at: Time.current)
zp_user.password = "humana1234" if zp_user.new_record? || !zp_user.authenticate("humana1234")
zp_user.save!

# =============================================================================
# Clients for new agencies
# =============================================================================

# Wellness Travel Co clients
wtc_c1 = Client.find_or_create_by!(organization: wellness_co_org, name: "Isabel Torres") do |c|
  c.email = "isabel.torres@email.com"
  c.phone = "+34 611 222 333"
  c.notes = "C-suite executive. Prefers luxury wellness programs with medical supervision."
end

wtc_c2 = Client.find_or_create_by!(organization: wellness_co_org, name: "Fernando Ruiz") do |c|
  c.email = "fernando.ruiz@email.com"
  c.phone = "+34 622 333 444"
  c.notes = "Repeat client. Interested in detox programs. Gluten-free diet."
end

wtc_c3 = Client.find_or_create_by!(organization: wellness_co_org, name: "Patricia López") do |c|
  c.email = "patricia.lopez@email.com"
  c.phone = "+34 633 444 555"
  c.notes = "Recently retired. First wellness retreat. Interested in yoga beginners programs."
end

# ZenPath clients
zp_c1 = Client.find_or_create_by!(organization: zenpath_org, name: "Mikel Arana") do |c|
  c.email = "mikel.arana@email.com"
  c.phone = "+34 644 555 666"
  c.notes = "Ex-athlete. Looking for body recovery retreats."
end

zp_c2 = Client.find_or_create_by!(organization: zenpath_org, name: "Amaia Goikoetxea") do |c|
  c.email = "amaia.goiko@email.com"
  c.phone = "+34 655 666 777"
  c.notes = "Yoga instructor looking for advanced retreats."
end

# =============================================================================
# Bookings across multiple months (for revenue chart & booking table)
# =============================================================================
puts "  Creating office-region bookings..."

office_bookings_data = [
  # --- January 2026 ---
  { org: wellness_co_org, exp: aia_exp, client: wtc_c1, rt: suite, guests: 1, status: "completed",
    starts: Date.new(2026, 1, 10), ends: Date.new(2026, 1, 17), notes: "Executive wellness week" },
  # --- February 2026 ---
  { org: agency_org, exp: aia_exp, client: carlos, rt: standard, guests: 2, status: "completed",
    starts: Date.new(2026, 2, 5), ends: Date.new(2026, 2, 12), notes: "Corporate team building" },
  { org: wellness_co_org, exp: sha_exp, client: wtc_c2, rt: sha_deluxe, guests: 1, status: "completed",
    starts: Date.new(2026, 2, 15), ends: Date.new(2026, 2, 22), notes: "Detox program" },
  # --- March 2026 ---
  { org: zenpath_org, exp: aia_exp, client: zp_c1, rt: suite, guests: 1, status: "completed",
    starts: Date.new(2026, 3, 1), ends: Date.new(2026, 3, 8), notes: "Recovery retreat" },
  { org: wellness_co_org, exp: calreiet_exp, client: wtc_c3, rt: calreiet_std, guests: 1, status: "completed",
    starts: Date.new(2026, 3, 10), ends: Date.new(2026, 3, 15), notes: "First retreat experience" },
  { org: agency_org, exp: sha_exp, client: maria, rt: sha_suite, guests: 2, status: "completed",
    starts: Date.new(2026, 3, 20), ends: Date.new(2026, 3, 27), notes: "Longevity program for couple" },
  # --- April 2026 ---
  { org: zenpath_org, exp: calreiet_exp, client: zp_c2, rt: calreiet_suite, guests: 1, status: "completed",
    starts: Date.new(2026, 4, 5), ends: Date.new(2026, 4, 10), notes: "Advanced yoga retreat" },
  { org: wellness_co_org, exp: aia_exp, client: wtc_c1, rt: villa, guests: 4, status: "completed",
    starts: Date.new(2026, 4, 12), ends: Date.new(2026, 4, 19), notes: "Family wellness getaway" },
  # --- May 2026 ---
  { org: agency_org, exp: calreiet_exp, client: carlos, rt: calreiet_suite, guests: 2, status: "completed",
    starts: Date.new(2026, 5, 1), ends: Date.new(2026, 5, 6), notes: "Corporate retreat" },
  { org: zenpath_org, exp: sha_exp, client: zp_c1, rt: sha_suite, guests: 1, status: "completed",
    starts: Date.new(2026, 5, 15), ends: Date.new(2026, 5, 22), notes: "Sports recovery" },
  { org: wellness_co_org, exp: aia_exp, client: wtc_c2, rt: standard, guests: 1, status: "completed",
    starts: Date.new(2026, 5, 20), ends: Date.new(2026, 5, 27), notes: "Yoga intensive" },
  # --- June 2026 ---
  { org: wellness_co_org, exp: sha_exp, client: wtc_c1, rt: sha_suite, guests: 2, status: "completed",
    starts: Date.new(2026, 6, 1), ends: Date.new(2026, 6, 8), notes: "Anti-aging program" },
  { org: agency_org, exp: aia_exp, client: maria, rt: suite, guests: 2, status: "completed",
    starts: Date.new(2026, 6, 15), ends: Date.new(2026, 6, 22), notes: "Summer yoga retreat" },
  { org: zenpath_org, exp: calreiet_exp, client: zp_c2, rt: calreiet_std, guests: 1, status: "completed",
    starts: Date.new(2026, 6, 20), ends: Date.new(2026, 6, 25), notes: "Detox weekend" },
  # --- July 2026 ---
  { org: wellness_co_org, exp: aia_exp, client: wtc_c3, rt: villa, guests: 3, status: "completed",
    starts: Date.new(2026, 7, 5), ends: Date.new(2026, 7, 12), notes: "Family retreat" },
  { org: agency_org, exp: sha_exp, client: carlos, rt: sha_deluxe, guests: 1, status: "completed",
    starts: Date.new(2026, 7, 10), ends: Date.new(2026, 7, 17), notes: "Longevity check" },
  { org: zenpath_org, exp: aia_exp, client: zp_c1, rt: standard, guests: 2, status: "completed",
    starts: Date.new(2026, 7, 20), ends: Date.new(2026, 7, 27), notes: "Couple's retreat" },
  # --- August 2026 (current month — recent activity) ---
  { org: wellness_co_org, exp: calreiet_exp, client: wtc_c1, rt: calreiet_suite, guests: 1, status: "confirmed",
    starts: Date.new(2026, 8, 10), ends: Date.new(2026, 8, 15), notes: "Summer detox" },
  { org: wellness_co_org, exp: sha_exp, client: wtc_c2, rt: sha_suite, guests: 1, status: "confirmed",
    starts: Date.new(2026, 8, 15), ends: Date.new(2026, 8, 22), notes: "Longevity assessment" },
  { org: agency_org, exp: aia_exp, client: maria, rt: suite, guests: 2, status: "confirmed",
    starts: Date.new(2026, 8, 18), ends: Date.new(2026, 8, 25), notes: "Anniversary retreat" },
  { org: zenpath_org, exp: sha_exp, client: zp_c2, rt: sha_deluxe, guests: 1, status: "inquiry",
    starts: Date.new(2026, 8, 25), ends: Date.new(2026, 9, 1), notes: "Exploring anti-aging options" },
  # --- September / October 2026 (upcoming) ---
  { org: wellness_co_org, exp: aia_exp, client: wtc_c3, rt: standard, guests: 1, status: "confirmed",
    starts: Date.new(2026, 9, 15), ends: Date.new(2026, 9, 22), notes: "Autumn retreat" },
  { org: zenpath_org, exp: calreiet_exp, client: zp_c1, rt: calreiet_suite, guests: 2, status: "inquiry",
    starts: Date.new(2026, 10, 12), ends: Date.new(2026, 10, 17), notes: "Post-season recovery" },
  # --- Cancelled bookings (for filter variety) ---
  { org: agency_org, exp: calreiet_exp, client: carlos, rt: calreiet_std, guests: 1, status: "cancelled",
    starts: Date.new(2026, 4, 20), ends: Date.new(2026, 4, 25), notes: "Client changed plans" },
  { org: zenpath_org, exp: aia_exp, client: zp_c2, rt: suite, guests: 1, status: "cancelled",
    starts: Date.new(2026, 5, 10), ends: Date.new(2026, 5, 17), notes: "Schedule conflict" },
]

office_bookings_data.each do |bd|
  # Check if a similar booking already exists to keep seeds idempotent
  existing = Booking.where(
    organization: bd[:org],
    experience: bd[:exp],
    client: bd[:client],
    status: bd[:status],
    starts_on: bd[:starts]
  ).exists?

  next if existing

  Booking.create!(
    organization: bd[:org],
    experience: bd[:exp],
    client: bd[:client],
    room_type: bd[:rt],
    guests: bd[:guests],
    status: bd[:status],
    starts_on: bd[:starts],
    ends_on: bd[:ends],
    notes: bd[:notes]
  )
end

# =============================================================================
# Assign all Spanish orgs to Office
# =============================================================================
Organization.where(kind: "hotel", country_code: "ES").update_all(assigned_office_id: office_org.id)
Organization.where(kind: "agency", country_code: "ES").update_all(assigned_office_id: office_org.id)

# =============================================================================
# Summary
# =============================================================================
puts "Development seed data created!"
puts "  Hotels:           #{Hotel.count}"
puts "  Room Types:       #{RoomType.count}"
puts "  Rooms:            #{Room.count}"
puts "  Amenities:        #{HotelAmenity.count}"
puts "  Retreats:         #{Retreat.count}"
puts "  Experiences:      #{Experience.count}"
puts "  Avail. Blocks:    #{AvailabilityBlock.count}"
puts "  Clients:          #{Client.count}"
puts "  Bookings:         #{Booking.count}"
puts "  Office Orgs:      #{Organization.where(kind: 'office').count}"
puts "  Office Region:    #{Organization.where(assigned_office_id: Organization.where(kind: 'office').select(:id)).count} orgs assigned"
puts ""
puts "Login credentials:"
puts "  admin@humana.global / humana1234"
puts "  hotel@aia.com / humana1234"
puts "  hotel@santuariodelsol.mx / humana1234"
puts "  hotel@calreiet.com / humana1234"
puts "  hotel@sha.com / humana1234"
puts "  hotel@airedebardenas.com / humana1234"
puts "  agent@viajeseter.com / humana1234"
puts "  agent@wellnesstravelco.es / humana1234"
puts "  agent@zenpath.es / humana1234"
puts "  office@humana.global / humana1234"

# =============================================================================
# ARGENTINA OFFICE — jonaawtf@gmail.com
# Full data: 4 hotels, 5 agencies, 4 retreats, many bookings
# =============================================================================
puts ""
puts "Seeding HUMANA Argentina data for jonaawtf@gmail.com..."

# --- Office ---
ar_office_org = Organization.find_or_create_by!(name: "HUMANA Argentina") do |o|
  o.kind = "office"
  o.status = "verified"
  o.city = "Buenos Aires"
  o.country = "Argentina"
  o.country_code = "AR"
  o.contact_email = "jonaawtf@gmail.com"
  o.phone = "+54 11 4000 0000"
  o.description = "HUMANA regional office for Argentina. Manages hotels and agencies operating in the Argentine market."
  o.onboarding_completed_at = Time.current
end

ar_office_user = User.find_or_initialize_by(email: "jonaawtf@gmail.com")
ar_office_user.assign_attributes(
  organization: ar_office_org,
  name: "Jonathan Rinaldelli",
  role: "owner",
  status: "active",
  locale: "es",
  onboarding_completed_at: Time.current
)
ar_office_user.password = "humana1234" if ar_office_user.new_record? || !ar_office_user.authenticate("humana1234")
ar_office_user.save!

# =============================================================================
# Argentine Hotels (4)
# =============================================================================

# Hotel AR-1: Termas de Cacheuta (Mendoza)
cacheuta_org = Organization.find_or_create_by!(name: "Termas de Cacheuta") do |o|
  o.kind = "hotel"
  o.status = "verified"
  o.city = "Cacheuta"
  o.country = "Argentina"
  o.country_code = "AR"
  o.contact_email = "info@termascacheuta.com"
  o.website = "https://termascacheuta.com"
  o.legal_name = "Termas de Cacheuta SA"
  o.phone = "+54 261 490 0000"
  o.description = "Historic thermal spa resort nestled in the Andes foothills of Mendoza."
  o.specialties = %w[wellness thermal nature wine]
  o.onboarding_completed_at = Time.current
  o.assigned_office_id = ar_office_org.id
end

cacheuta_hotel = Hotel.find_or_create_by!(organization: cacheuta_org) do |h|
  h.name = "Termas de Cacheuta"
  h.city = "Cacheuta"
  h.country = "Argentina"
  h.country_code = "AR"
  h.latitude = -33.0125
  h.longitude = -69.1167
  h.stars = 4
  h.check_in_time = "14:00"
  h.check_out_time = "10:00"
  h.wellness_standard = "Thermal Wellness"
  h.address = "Ruta Provincial 82 Km 38, Cacheuta"
  h.postal_code = "5549"
  h.phone = "+54 261 490 0000"
  h.certified = true
  h.description = "A legendary thermal spa resort at the foot of the Andes, where natural hot springs and mountain air create the perfect healing environment."
  h.total_rooms = 20
  h.contact_email = "reservas@termascacheuta.com"
  h.website = "https://termascacheuta.com"
  h.onboarding_completed_at = Time.current
end

cacheuta_user = User.find_or_initialize_by(email: "hotel@termascacheuta.com")
cacheuta_user.assign_attributes(organization: cacheuta_org, name: "Martín Bustos", role: "owner", status: "active", locale: "es", onboarding_completed_at: Time.current)
cacheuta_user.password = "humana1234" if cacheuta_user.new_record? || !cacheuta_user.authenticate("humana1234")
cacheuta_user.save!

cacheuta_termal = RoomType.find_or_create_by!(hotel: cacheuta_hotel, name: "Suite Termal") do |rt|
  rt.category = "suite"
  rt.capacity = 2
  rt.area_sqm = 48
  rt.price_per_night_cents = 4500000
  rt.currency = "ARS"
  rt.description = "Suite with private thermal pool and Andes mountain views."
  rt.total_rooms = 6
  rt.bed_type = "king"
  rt.view_type = "mountain_view"
  rt.amenities = ["Wi-Fi", "Private Thermal Pool", "Mountain View", "Minibar", "Bathrobe"]
  rt.position = 0
  rt.status = "active"
end

cacheuta_std = RoomType.find_or_create_by!(hotel: cacheuta_hotel, name: "Habitación Clásica") do |rt|
  rt.category = "standard"
  rt.capacity = 2
  rt.area_sqm = 30
  rt.price_per_night_cents = 2800000
  rt.currency = "ARS"
  rt.description = "Comfortable room with access to all thermal pools and spa facilities."
  rt.total_rooms = 14
  rt.bed_type = "queen"
  rt.view_type = "garden_view"
  rt.amenities = ["Wi-Fi", "Air Conditioning", "Garden View", "En-suite Bathroom"]
  rt.position = 1
  rt.status = "active"
end

[
  { name: "Piscinas Termales", category: "wellness", icon: "pool", position: 0, featured: true },
  { name: "Spa & Masajes", category: "wellness", icon: "spa", position: 1, featured: true },
  { name: "Restaurante Regional", category: "dining", icon: "restaurant", position: 2, featured: true },
  { name: "Senderos de Montaña", category: "recreation", icon: "hiking", position: 3, featured: true },
].each do |attrs|
  HotelAmenity.find_or_create_by!(hotel: cacheuta_hotel, name: attrs[:name]) do |a|
    a.assign_attributes(attrs)
  end
end

# Hotel AR-2: Llao Llao Resort (Bariloche)
llaollao_org = Organization.find_or_create_by!(name: "Llao Llao Resort & Spa") do |o|
  o.kind = "hotel"
  o.status = "verified"
  o.city = "San Carlos de Bariloche"
  o.country = "Argentina"
  o.country_code = "AR"
  o.contact_email = "info@llaollao.com"
  o.website = "https://llaollao.com"
  o.legal_name = "Llao Llao Resorts SA"
  o.phone = "+54 294 444 8530"
  o.description = "Iconic Patagonian resort surrounded by lakes, forests, and snow-capped mountains."
  o.specialties = %w[wellness luxury nature adventure]
  o.onboarding_completed_at = Time.current
  o.assigned_office_id = ar_office_org.id
end

llaollao_hotel = Hotel.find_or_create_by!(organization: llaollao_org) do |h|
  h.name = "Llao Llao Resort & Spa"
  h.city = "San Carlos de Bariloche"
  h.country = "Argentina"
  h.country_code = "AR"
  h.latitude = -41.0556
  h.longitude = -71.5444
  h.stars = 5
  h.check_in_time = "15:00"
  h.check_out_time = "11:00"
  h.wellness_standard = "Luxury Wellness"
  h.address = "Av. Ezequiel Bustillo Km 25, Bariloche"
  h.postal_code = "8400"
  h.phone = "+54 294 444 8530"
  h.certified = true
  h.description = "The crown jewel of Argentine hospitality, set on a private peninsula between lakes Nahuel Huapi and Moreno with breathtaking Patagonian landscapes."
  h.total_rooms = 30
  h.contact_email = "reservas@llaollao.com"
  h.website = "https://llaollao.com"
  h.onboarding_completed_at = Time.current
end

llaollao_user = User.find_or_initialize_by(email: "hotel@llaollao.com")
llaollao_user.assign_attributes(organization: llaollao_org, name: "Valentina Soria", role: "owner", status: "active", locale: "es", onboarding_completed_at: Time.current)
llaollao_user.password = "humana1234" if llaollao_user.new_record? || !llaollao_user.authenticate("humana1234")
llaollao_user.save!

llaollao_lake = RoomType.find_or_create_by!(hotel: llaollao_hotel, name: "Lake View Suite") do |rt|
  rt.category = "suite"
  rt.capacity = 2
  rt.area_sqm = 55
  rt.price_per_night_cents = 7500000
  rt.currency = "ARS"
  rt.description = "Premium suite with panoramic lake and mountain views from private balcony."
  rt.total_rooms = 10
  rt.bed_type = "king"
  rt.view_type = "lake_view"
  rt.amenities = ["Wi-Fi", "Air Conditioning", "Private Balcony", "Lake View", "Minibar", "Fireplace"]
  rt.position = 0
  rt.status = "active"
end

llaollao_std = RoomType.find_or_create_by!(hotel: llaollao_hotel, name: "Mountain Room") do |rt|
  rt.category = "superior"
  rt.capacity = 2
  rt.area_sqm = 35
  rt.price_per_night_cents = 5000000
  rt.currency = "ARS"
  rt.description = "Elegant room with mountain views and access to the spa & golf course."
  rt.total_rooms = 20
  rt.bed_type = "king"
  rt.view_type = "mountain_view"
  rt.amenities = ["Wi-Fi", "Air Conditioning", "Mountain View", "En-suite Bathroom", "Bathrobe"]
  rt.position = 1
  rt.status = "active"
end

# Hotel AR-3: Cavas Wine Lodge (Mendoza)
cavas_org = Organization.find_or_create_by!(name: "Cavas Wine Lodge") do |o|
  o.kind = "hotel"
  o.status = "verified"
  o.city = "Luján de Cuyo"
  o.country = "Argentina"
  o.country_code = "AR"
  o.contact_email = "info@cavaslodge.com"
  o.website = "https://cavaslodge.com"
  o.legal_name = "Cavas Wine Lodge SA"
  o.phone = "+54 261 410 6927"
  o.description = "Boutique wine lodge set among vineyards with Andes backdrop, combining wine culture and wellness."
  o.specialties = %w[wine wellness gastronomy nature]
  o.onboarding_completed_at = Time.current
  o.assigned_office_id = ar_office_org.id
end

cavas_hotel = Hotel.find_or_create_by!(organization: cavas_org) do |h|
  h.name = "Cavas Wine Lodge"
  h.city = "Luján de Cuyo"
  h.country = "Argentina"
  h.country_code = "AR"
  h.latitude = -33.0833
  h.longitude = -68.5667
  h.stars = 5
  h.check_in_time = "15:00"
  h.check_out_time = "11:00"
  h.wellness_standard = "Wine & Wellness"
  h.address = "Costaflores s/n, Alto Agrelo, Luján de Cuyo"
  h.postal_code = "5507"
  h.phone = "+54 261 410 6927"
  h.certified = true
  h.description = "An intimate wine lodge surrounded by 35 acres of Malbec vineyards with views of the Andes. Vinotherapy spa, farm-to-table dining, and curated wine experiences."
  h.total_rooms = 18
  h.contact_email = "reservas@cavaslodge.com"
  h.website = "https://cavaslodge.com"
  h.onboarding_completed_at = Time.current
end

cavas_user = User.find_or_initialize_by(email: "hotel@cavaslodge.com")
cavas_user.assign_attributes(organization: cavas_org, name: "Luciano Prieto", role: "owner", status: "active", locale: "es", onboarding_completed_at: Time.current)
cavas_user.password = "humana1234" if cavas_user.new_record? || !cavas_user.authenticate("humana1234")
cavas_user.save!

cavas_villa = RoomType.find_or_create_by!(hotel: cavas_hotel, name: "Vineyard Villa") do |rt|
  rt.category = "villa"
  rt.capacity = 2
  rt.area_sqm = 65
  rt.price_per_night_cents = 8500000
  rt.currency = "ARS"
  rt.description = "Private villa with plunge pool overlooking the vineyards and Andes."
  rt.total_rooms = 6
  rt.bed_type = "king"
  rt.view_type = "vineyard_view"
  rt.amenities = ["Wi-Fi", "Private Pool", "Vineyard View", "Outdoor Shower", "Fireplace", "Minibar"]
  rt.position = 0
  rt.status = "active"
end

cavas_std = RoomType.find_or_create_by!(hotel: cavas_hotel, name: "Wine Cellar Room") do |rt|
  rt.category = "standard"
  rt.capacity = 2
  rt.area_sqm = 35
  rt.price_per_night_cents = 5500000
  rt.currency = "ARS"
  rt.description = "Cozy room with vineyard views and private patio."
  rt.total_rooms = 12
  rt.bed_type = "queen"
  rt.view_type = "vineyard_view"
  rt.amenities = ["Wi-Fi", "Air Conditioning", "Private Patio", "Vineyard View"]
  rt.position = 1
  rt.status = "active"
end

# Hotel AR-4: Posada Borravino (Salta — pending status)
borravino_org = Organization.find_or_create_by!(name: "Posada Borravino") do |o|
  o.kind = "hotel"
  o.status = "pending"
  o.city = "Cafayate"
  o.country = "Argentina"
  o.country_code = "AR"
  o.contact_email = "info@borravino.com"
  o.website = "https://borravino.com"
  o.legal_name = "Posada Borravino SRL"
  o.phone = "+54 3868 422 000"
  o.description = "Artisan boutique posada in the Calchaquí Valley wine region."
  o.specialties = %w[wine nature gastronomy]
  o.onboarding_completed_at = Time.current
  o.assigned_office_id = ar_office_org.id
end

borravino_hotel = Hotel.find_or_create_by!(organization: borravino_org) do |h|
  h.name = "Posada Borravino"
  h.city = "Cafayate"
  h.country = "Argentina"
  h.country_code = "AR"
  h.latitude = -26.0724
  h.longitude = -66.0317
  h.stars = 3
  h.check_in_time = "14:00"
  h.check_out_time = "10:00"
  h.wellness_standard = "Rural Wellness"
  h.address = "Ruta 40 Km 4340, Cafayate"
  h.postal_code = "4427"
  h.phone = "+54 3868 422 000"
  h.certified = false
  h.description = "An intimate posada surrounded by Torrontés vineyards in the dramatic Quebrada de las Flechas landscape."
  h.total_rooms = 8
  h.contact_email = "reservas@borravino.com"
  h.website = "https://borravino.com"
  h.onboarding_completed_at = Time.current
end

borravino_user = User.find_or_initialize_by(email: "hotel@borravino.com")
borravino_user.assign_attributes(organization: borravino_org, name: "Guadalupe Funes", role: "owner", status: "pending", locale: "es", onboarding_completed_at: Time.current)
borravino_user.password = "humana1234" if borravino_user.new_record? || !borravino_user.authenticate("humana1234")
borravino_user.save!

borravino_std = RoomType.find_or_create_by!(hotel: borravino_hotel, name: "Habitación Viñedo") do |rt|
  rt.category = "standard"
  rt.capacity = 2
  rt.area_sqm = 28
  rt.price_per_night_cents = 3200000
  rt.currency = "ARS"
  rt.description = "Room with vineyard views and rustic charm."
  rt.total_rooms = 8
  rt.bed_type = "queen"
  rt.view_type = "vineyard_view"
  rt.amenities = ["Wi-Fi", "Ceiling Fan", "Vineyard View", "Private Bathroom"]
  rt.position = 0
  rt.status = "active"
end

# =============================================================================
# Argentine Agencies (5)
# =============================================================================

# Agency AR-1: Alma Viajera (Buenos Aires)
alma_org = Organization.find_or_create_by!(name: "Alma Viajera") do |o|
  o.kind = "agency"
  o.status = "verified"
  o.city = "Buenos Aires"
  o.country = "Argentina"
  o.country_code = "AR"
  o.contact_email = "hola@almaviajera.com.ar"
  o.website = "https://almaviajera.com.ar"
  o.legal_name = "Alma Viajera SRL"
  o.phone = "+54 11 5555 1234"
  o.description = "Agencia de viajes boutique especializada en retiros de bienestar y experiencias transformadoras."
  o.specialties = %w[wellness yoga spiritual]
  o.onboarding_completed_at = Time.current
  o.assigned_office_id = ar_office_org.id
end

alma_user = User.find_or_initialize_by(email: "agent@almaviajera.com.ar")
alma_user.assign_attributes(organization: alma_org, name: "Camila Suárez", role: "owner", status: "active", locale: "es", onboarding_completed_at: Time.current)
alma_user.password = "humana1234" if alma_user.new_record? || !alma_user.authenticate("humana1234")
alma_user.save!

# Agency AR-2: Senderos del Sur (Mendoza)
senderos_org = Organization.find_or_create_by!(name: "Senderos del Sur") do |o|
  o.kind = "agency"
  o.status = "verified"
  o.city = "Mendoza"
  o.country = "Argentina"
  o.country_code = "AR"
  o.contact_email = "info@senderosdelsur.com.ar"
  o.website = "https://senderosdelsur.com.ar"
  o.legal_name = "Senderos del Sur SA"
  o.phone = "+54 261 555 6789"
  o.description = "Agencia de turismo receptivo especializada en enoturismo y wellness en Cuyo."
  o.specialties = %w[wine wellness nature adventure]
  o.onboarding_completed_at = Time.current
  o.assigned_office_id = ar_office_org.id
end

senderos_user = User.find_or_initialize_by(email: "agent@senderosdelsur.com.ar")
senderos_user.assign_attributes(organization: senderos_org, name: "Matías Álvarez", role: "owner", status: "active", locale: "es", onboarding_completed_at: Time.current)
senderos_user.password = "humana1234" if senderos_user.new_record? || !senderos_user.authenticate("humana1234")
senderos_user.save!

# Agency AR-3: Patagonia Retreats (Bariloche)
patagonia_org = Organization.find_or_create_by!(name: "Patagonia Retreats") do |o|
  o.kind = "agency"
  o.status = "verified"
  o.city = "San Carlos de Bariloche"
  o.country = "Argentina"
  o.country_code = "AR"
  o.contact_email = "hello@patagoniaretreat.com"
  o.website = "https://patagoniaretreat.com"
  o.legal_name = "Patagonia Retreats SRL"
  o.phone = "+54 294 555 3456"
  o.description = "Boutique travel agency curating luxury Patagonian wellness and adventure experiences."
  o.specialties = %w[luxury adventure nature wellness]
  o.onboarding_completed_at = Time.current
  o.assigned_office_id = ar_office_org.id
end

pata_user = User.find_or_initialize_by(email: "agent@patagoniaretreat.com")
pata_user.assign_attributes(organization: patagonia_org, name: "Florencia Lagos", role: "owner", status: "active", locale: "es", onboarding_completed_at: Time.current)
pata_user.password = "humana1234" if pata_user.new_record? || !pata_user.authenticate("humana1234")
pata_user.save!

# Agency AR-4: Bienestar Total (Córdoba — pending)
bienestar_org = Organization.find_or_create_by!(name: "Bienestar Total") do |o|
  o.kind = "agency"
  o.status = "pending"
  o.city = "Córdoba"
  o.country = "Argentina"
  o.country_code = "AR"
  o.contact_email = "contacto@bienestartotal.com.ar"
  o.legal_name = "Bienestar Total SRL"
  o.phone = "+54 351 555 7890"
  o.description = "Agencia de bienestar integral con foco en retiros corporativos."
  o.specialties = %w[corporate wellness yoga]
  o.onboarding_completed_at = Time.current
  o.assigned_office_id = ar_office_org.id
end

bienestar_user = User.find_or_initialize_by(email: "agent@bienestartotal.com.ar")
bienestar_user.assign_attributes(organization: bienestar_org, name: "Nicolás Pereyra", role: "owner", status: "pending", locale: "es", onboarding_completed_at: Time.current)
bienestar_user.password = "humana1234" if bienestar_user.new_record? || !bienestar_user.authenticate("humana1234")
bienestar_user.save!

# Agency AR-5: Viajes Wellness BA (Buenos Aires)
vwba_org = Organization.find_or_create_by!(name: "Viajes Wellness BA") do |o|
  o.kind = "agency"
  o.status = "verified"
  o.city = "Buenos Aires"
  o.country = "Argentina"
  o.country_code = "AR"
  o.contact_email = "info@wellnessba.com.ar"
  o.website = "https://wellnessba.com.ar"
  o.legal_name = "Viajes Wellness BA SAS"
  o.phone = "+54 11 5555 9012"
  o.description = "Tu puerta de entrada al bienestar en Argentina. Retiros, spa weekends y experiencias transformadoras."
  o.specialties = %w[wellness spa yoga luxury]
  o.onboarding_completed_at = Time.current
  o.assigned_office_id = ar_office_org.id
end

vwba_user = User.find_or_initialize_by(email: "agent@wellnessba.com.ar")
vwba_user.assign_attributes(organization: vwba_org, name: "Julieta Paz", role: "owner", status: "active", locale: "es", onboarding_completed_at: Time.current)
vwba_user.password = "humana1234" if vwba_user.new_record? || !vwba_user.authenticate("humana1234")
vwba_user.save!

# =============================================================================
# Argentine Retreats (4)
# =============================================================================

# Retreat AR-1: Retiro Termal Andino (Cacheuta)
ar_retreat1 = Retreat.find_or_initialize_by(slug: "retiro-termal-andino")
ar_retreat1.assign_attributes(
  name: "Retiro Termal Andino",
  hotel: cacheuta_hotel,
  created_by_organization: cacheuta_org,
  retreat_type: "wellness",
  status: "active",
  duration_nights: 5,
  starts_on: Date.new(2026, 9, 20),
  ends_on: Date.new(2026, 9, 25),
  capacity: 16,
  language: "es",
  description: "Cinco noches de inmersión en las aguas termales de los Andes. Combina baños termales, masajes con piedras volcánicas y caminatas por senderos de montaña.",
  short_description: "5 noches de retiro termal en los Andes mendocinos.",
  location: "Cacheuta",
  country: "Argentina",
  country_code: "AR",
  currency: "ARS",
  commission_rate: 0.16,
  featured: true,
  certified: true,
  created_by_type: "hotel",
  published_at: Time.current
)
ar_retreat1.save!

5.times do |i|
  day = RetreatDay.find_or_create_by!(retreat: ar_retreat1, day_number: i + 1) do |d|
    d.title = "Día #{i + 1}"
  end
  [
    { name: "Meditación al Amanecer", time: "07:00", duration_minutes: 45, position: 0, category: "meditation" },
    { name: "Baño Termal Guiado", time: "09:00", duration_minutes: 90, position: 1, category: "spa" },
    { name: "Caminata de Montaña", time: "15:00", duration_minutes: 120, position: 2, category: "excursion" },
  ].each do |act|
    RetreatActivity.find_or_create_by!(retreat_day: day, name: act[:name]) do |a|
      a.assign_attributes(act)
    end
  end
end

RetreatFacilitator.find_or_create_by!(retreat: ar_retreat1, name: "Dr. Sebastián Molina") do |f|
  f.role = "lead"
  f.specialty = "Hidrología Médica"
  f.bio = "Médico especialista en terapias termales con 15 años de experiencia en balneología."
  f.position = 0
end

[
  { name: "Baños termales ilimitados", category: "wellness", icon: "pool", position: 0 },
  { name: "Pensión completa", category: "meal", icon: "restaurant", position: 1 },
  { name: "1 Masaje con piedras", category: "wellness", icon: "spa", position: 2 },
].each do |inc|
  RetreatInclusion.find_or_create_by!(retreat: ar_retreat1, name: inc[:name]) do |i|
    i.assign_attributes(inc)
  end
end

[
  { room_type: cacheuta_termal, price_per_guest_cents: 22000000, occupancy_label: "Suite Termal", max_guests: 1, currency: "ARS" },
  { room_type: cacheuta_std, price_per_guest_cents: 14000000, occupancy_label: "Habitación Clásica", max_guests: 1, currency: "ARS" },
].each do |p_attrs|
  RetreatPricing.find_or_create_by!(retreat: ar_retreat1, room_type: p_attrs[:room_type]) do |p|
    p.assign_attributes(p_attrs.except(:room_type))
  end
end
ar_retreat1.save!

ar_exp1 = Experience.find_or_initialize_by(slug: "retiro-termal-andino-cacheuta")
ar_exp1.assign_attributes(
  hotel: cacheuta_hotel, kind: "wellness",
  title: "Retiro Termal Andino — Cacheuta",
  description: ar_retreat1.description,
  location: "Cacheuta", country: "Argentina", country_code: "AR",
  starts_on: ar_retreat1.starts_on, ends_on: ar_retreat1.ends_on,
  price_cents: ar_retreat1.min_price_cents, currency: "ARS",
  capacity: 16, commission_rate: 0.16, status: "active",
  image_url: "https://images.unsplash.com/photo-1554232456-8727aae0cfa4?w=800"
)
ar_exp1.save!

# Retreat AR-2: Patagonia Wellness Experience (Llao Llao)
ar_retreat2 = Retreat.find_or_initialize_by(slug: "patagonia-wellness-experience")
ar_retreat2.assign_attributes(
  name: "Patagonia Wellness Experience",
  hotel: llaollao_hotel,
  created_by_organization: llaollao_org,
  retreat_type: "mindfulness",
  status: "active",
  duration_nights: 7,
  starts_on: Date.new(2026, 10, 10),
  ends_on: Date.new(2026, 10, 17),
  capacity: 20,
  language: "en",
  description: "Seven nights immersed in Patagonian wilderness. Lake kayaking, forest bathing, volcano trekking, and spa treatments in one of the world's most stunning landscapes.",
  short_description: "7-night luxury wellness in Patagonian lakeland.",
  location: "Bariloche",
  country: "Argentina",
  country_code: "AR",
  currency: "ARS",
  commission_rate: 0.16,
  featured: true,
  certified: true,
  created_by_type: "hotel",
  published_at: Time.current
)
ar_retreat2.save!

ar_exp2 = Experience.find_or_initialize_by(slug: "patagonia-wellness-bariloche")
ar_exp2.assign_attributes(
  hotel: llaollao_hotel, kind: "breathwork",
  title: "Patagonia Wellness Experience — Bariloche",
  description: ar_retreat2.description,
  location: "Bariloche", country: "Argentina", country_code: "AR",
  starts_on: ar_retreat2.starts_on, ends_on: ar_retreat2.ends_on,
  price_cents: 35000000, currency: "ARS",
  capacity: 20, commission_rate: 0.16, status: "active",
  image_url: "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800"
)
ar_exp2.save!

# Retreat AR-3: Vendimia & Vinotherapy (Cavas Wine Lodge)
ar_retreat3 = Retreat.find_or_initialize_by(slug: "vendimia-vinotherapy")
ar_retreat3.assign_attributes(
  name: "Vendimia & Vinotherapy Retreat",
  hotel: cavas_hotel,
  created_by_organization: cavas_org,
  retreat_type: "wellness",
  status: "active",
  duration_nights: 4,
  starts_on: Date.new(2026, 11, 5),
  ends_on: Date.new(2026, 11, 9),
  capacity: 14,
  language: "es",
  description: "Cuatro noches de vinoterapia, catas de Malbec, masajes con extractos de uva y gastronomía de autor entre viñedos al pie de los Andes.",
  short_description: "4 noches de vinoterapia y gastronomía en Mendoza.",
  location: "Luján de Cuyo",
  country: "Argentina",
  country_code: "AR",
  currency: "ARS",
  commission_rate: 0.16,
  featured: true,
  certified: true,
  created_by_type: "hotel",
  published_at: Time.current
)
ar_retreat3.save!

ar_exp3 = Experience.find_or_initialize_by(slug: "vendimia-vinotherapy-mendoza")
ar_exp3.assign_attributes(
  hotel: cavas_hotel, kind: "mindfulness",
  title: "Vendimia & Vinotherapy — Mendoza",
  description: ar_retreat3.description,
  location: "Luján de Cuyo", country: "Argentina", country_code: "AR",
  starts_on: ar_retreat3.starts_on, ends_on: ar_retreat3.ends_on,
  price_cents: 28000000, currency: "ARS",
  capacity: 14, commission_rate: 0.16, status: "active",
  image_url: "https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=800"
)
ar_exp3.save!

# Retreat AR-4: Silencio en la Quebrada (Borravino — draft)
ar_retreat4 = Retreat.find_or_initialize_by(slug: "silencio-en-la-quebrada")
ar_retreat4.assign_attributes(
  name: "Silencio en la Quebrada",
  hotel: borravino_hotel,
  created_by_organization: borravino_org,
  retreat_type: "constelaciones_familiares",
  status: "draft",
  duration_nights: 3,
  starts_on: Date.new(2026, 12, 10),
  ends_on: Date.new(2026, 12, 13),
  capacity: 8,
  language: "es",
  description: "Tres noches de retiro de silencio en la Quebrada de las Flechas. Desconexión digital, meditación caminando, yoga al amanecer y observación de estrellas.",
  short_description: "3 noches de silencio en la Quebrada de Cafayate.",
  location: "Cafayate",
  country: "Argentina",
  country_code: "AR",
  currency: "ARS",
  commission_rate: 0.16,
  featured: false,
  certified: false,
  created_by_type: "hotel"
)
ar_retreat4.save!

# =============================================================================
# Argentine Clients
# =============================================================================
alma_c1 = Client.find_or_create_by!(organization: alma_org, name: "Laura Fernández") do |c|
  c.email = "laura.fernandez@email.com"
  c.phone = "+54 11 6111 2222"
  c.notes = "Ejecutiva estresada. Busca desconexión total. Prefiere single."
end

alma_c2 = Client.find_or_create_by!(organization: alma_org, name: "Gonzalo Medina") do |c|
  c.email = "gonzalo.medina@email.com"
  c.phone = "+54 11 6222 3333"
  c.notes = "Deportista amateur. Interesado en recuperación muscular y termas."
end

senderos_c1 = Client.find_or_create_by!(organization: senderos_org, name: "Claudia Vargas") do |c|
  c.email = "claudia.vargas@email.com"
  c.phone = "+54 261 6333 4444"
  c.notes = "Sommelier. Busca experiencias de vinoterapia premium."
end

senderos_c2 = Client.find_or_create_by!(organization: senderos_org, name: "Ricardo Ortiz") do |c|
  c.email = "ricardo.ortiz@email.com"
  c.phone = "+54 261 6444 5555"
  c.notes = "Empresario. Interesado en corporate retreats para su equipo."
end

pata_c1 = Client.find_or_create_by!(organization: patagonia_org, name: "Santiago Quiroga") do |c|
  c.email = "santiago.quiroga@email.com"
  c.phone = "+54 294 6555 6666"
  c.notes = "Fotógrafo. Busca retiros en naturaleza con paisajes espectaculares."
end

pata_c2 = Client.find_or_create_by!(organization: patagonia_org, name: "Valentina Díaz") do |c|
  c.email = "valentina.diaz@email.com"
  c.phone = "+54 294 6666 7777"
  c.notes = "Pareja joven. Primera experiencia de wellness retreat."
end

vwba_c1 = Client.find_or_create_by!(organization: vwba_org, name: "Martina Acosta") do |c|
  c.email = "martina.acosta@email.com"
  c.phone = "+54 11 6777 8888"
  c.notes = "Instructora de yoga. Busca retiros avanzados."
end

vwba_c2 = Client.find_or_create_by!(organization: vwba_org, name: "Diego Romero") do |c|
  c.email = "diego.romero@email.com"
  c.phone = "+54 11 6888 9999"
  c.notes = "Médico. Interesado en retiros de meditación y mindfulness."
end

# =============================================================================
# Argentine Bookings (across months for revenue chart)
# =============================================================================
puts "  Creating Argentine office-region bookings..."

ar_bookings_data = [
  # --- January 2026 ---
  { org: alma_org, exp: ar_exp1, client: alma_c1, rt: cacheuta_termal, guests: 1, status: "completed",
    starts: Date.new(2026, 1, 8), ends: Date.new(2026, 1, 13), notes: "Retiro de inicio de año" },
  { org: senderos_org, exp: ar_exp3, client: senderos_c1, rt: cavas_villa, guests: 2, status: "completed",
    starts: Date.new(2026, 1, 20), ends: Date.new(2026, 1, 24), notes: "Vinoterapia para parejas" },
  # --- February 2026 ---
  { org: patagonia_org, exp: ar_exp2, client: pata_c1, rt: llaollao_lake, guests: 1, status: "completed",
    starts: Date.new(2026, 2, 5), ends: Date.new(2026, 2, 12), notes: "Fotografía y naturaleza" },
  { org: vwba_org, exp: ar_exp1, client: vwba_c1, rt: cacheuta_std, guests: 1, status: "completed",
    starts: Date.new(2026, 2, 15), ends: Date.new(2026, 2, 20), notes: "Retiro termal para instructora" },
  # --- March 2026 ---
  { org: alma_org, exp: ar_exp2, client: alma_c2, rt: llaollao_std, guests: 2, status: "completed",
    starts: Date.new(2026, 3, 1), ends: Date.new(2026, 3, 8), notes: "Recuperación deportiva en Patagonia" },
  { org: senderos_org, exp: ar_exp1, client: senderos_c2, rt: cacheuta_termal, guests: 4, status: "completed",
    starts: Date.new(2026, 3, 15), ends: Date.new(2026, 3, 20), notes: "Corporate retreat" },
  { org: vwba_org, exp: ar_exp3, client: vwba_c2, rt: cavas_std, guests: 1, status: "completed",
    starts: Date.new(2026, 3, 20), ends: Date.new(2026, 3, 24), notes: "Mindfulness y vino" },
  # --- April 2026 ---
  { org: patagonia_org, exp: ar_exp2, client: pata_c2, rt: llaollao_lake, guests: 2, status: "completed",
    starts: Date.new(2026, 4, 5), ends: Date.new(2026, 4, 12), notes: "Luna de miel wellness" },
  { org: alma_org, exp: ar_exp3, client: alma_c1, rt: cavas_villa, guests: 1, status: "completed",
    starts: Date.new(2026, 4, 15), ends: Date.new(2026, 4, 19), notes: "Escapada de otoño" },
  # --- May 2026 ---
  { org: senderos_org, exp: ar_exp2, client: senderos_c1, rt: llaollao_std, guests: 2, status: "completed",
    starts: Date.new(2026, 5, 1), ends: Date.new(2026, 5, 8), notes: "Aventura patagónica" },
  { org: vwba_org, exp: ar_exp1, client: vwba_c1, rt: cacheuta_termal, guests: 1, status: "completed",
    starts: Date.new(2026, 5, 10), ends: Date.new(2026, 5, 15), notes: "Retiro de invierno" },
  { org: patagonia_org, exp: ar_exp3, client: pata_c1, rt: cavas_std, guests: 1, status: "completed",
    starts: Date.new(2026, 5, 20), ends: Date.new(2026, 5, 24), notes: "Vinoterapia y fotos" },
  # --- June 2026 ---
  { org: alma_org, exp: ar_exp1, client: alma_c2, rt: cacheuta_std, guests: 2, status: "completed",
    starts: Date.new(2026, 6, 5), ends: Date.new(2026, 6, 10), notes: "Termas de invierno" },
  { org: senderos_org, exp: ar_exp3, client: senderos_c2, rt: cavas_villa, guests: 3, status: "completed",
    starts: Date.new(2026, 6, 15), ends: Date.new(2026, 6, 19), notes: "Retiro corporativo enológico" },
  { org: vwba_org, exp: ar_exp2, client: vwba_c2, rt: llaollao_lake, guests: 2, status: "completed",
    starts: Date.new(2026, 6, 20), ends: Date.new(2026, 6, 27), notes: "Ski & wellness" },
  # --- July 2026 ---
  { org: patagonia_org, exp: ar_exp2, client: pata_c2, rt: llaollao_std, guests: 2, status: "completed",
    starts: Date.new(2026, 7, 1), ends: Date.new(2026, 7, 8), notes: "Vacaciones de invierno" },
  { org: alma_org, exp: ar_exp3, client: alma_c1, rt: cavas_std, guests: 1, status: "completed",
    starts: Date.new(2026, 7, 10), ends: Date.new(2026, 7, 14), notes: "Vendimia tardía" },
  { org: senderos_org, exp: ar_exp1, client: senderos_c1, rt: cacheuta_termal, guests: 1, status: "completed",
    starts: Date.new(2026, 7, 20), ends: Date.new(2026, 7, 25), notes: "Termas y vino" },
  # --- August 2026 (current month) ---
  { org: alma_org, exp: ar_exp1, client: alma_c1, rt: cacheuta_termal, guests: 1, status: "confirmed",
    starts: Date.new(2026, 8, 5), ends: Date.new(2026, 8, 10), notes: "Retiro pre-primavera" },
  { org: patagonia_org, exp: ar_exp2, client: pata_c1, rt: llaollao_lake, guests: 1, status: "confirmed",
    starts: Date.new(2026, 8, 10), ends: Date.new(2026, 8, 17), notes: "Fotografía invernal" },
  { org: vwba_org, exp: ar_exp3, client: vwba_c1, rt: cavas_villa, guests: 2, status: "confirmed",
    starts: Date.new(2026, 8, 15), ends: Date.new(2026, 8, 19), notes: "Retiro de vinoterapia" },
  { org: senderos_org, exp: ar_exp2, client: senderos_c2, rt: llaollao_std, guests: 3, status: "inquiry",
    starts: Date.new(2026, 8, 25), ends: Date.new(2026, 9, 1), notes: "Evaluando team building" },
  # --- September / October 2026 (upcoming) ---
  { org: alma_org, exp: ar_exp1, client: alma_c2, rt: cacheuta_std, guests: 2, status: "confirmed",
    starts: Date.new(2026, 9, 20), ends: Date.new(2026, 9, 25), notes: "Retiro primaveral" },
  { org: patagonia_org, exp: ar_exp2, client: pata_c2, rt: llaollao_lake, guests: 2, status: "inquiry",
    starts: Date.new(2026, 10, 10), ends: Date.new(2026, 10, 17), notes: "Primavera en Patagonia" },
  # --- Cancelled ---
  { org: senderos_org, exp: ar_exp3, client: senderos_c1, rt: cavas_std, guests: 1, status: "cancelled",
    starts: Date.new(2026, 4, 1), ends: Date.new(2026, 4, 5), notes: "Cambio de planes" },
  { org: vwba_org, exp: ar_exp1, client: vwba_c2, rt: cacheuta_std, guests: 1, status: "cancelled",
    starts: Date.new(2026, 6, 1), ends: Date.new(2026, 6, 6), notes: "Conflicto de agenda" },
]

ar_bookings_data.each do |bd|
  existing = Booking.where(
    organization: bd[:org],
    experience: bd[:exp],
    client: bd[:client],
    status: bd[:status],
    starts_on: bd[:starts]
  ).exists?

  next if existing

  Booking.create!(
    organization: bd[:org],
    experience: bd[:exp],
    client: bd[:client],
    room_type: bd[:rt],
    guests: bd[:guests],
    status: bd[:status],
    starts_on: bd[:starts],
    ends_on: bd[:ends],
    notes: bd[:notes]
  )
end

# Assign all Argentine orgs to the AR office
Organization.where(kind: "hotel", country_code: "AR").update_all(assigned_office_id: ar_office_org.id)
Organization.where(kind: "agency", country_code: "AR").update_all(assigned_office_id: ar_office_org.id)

puts "Argentina seed data created!"
puts "  AR Hotels:      #{Hotel.joins(:organization).where(organizations: { country_code: 'AR' }).count}"
puts "  AR Agencies:    #{Organization.where(kind: 'agency', country_code: 'AR').count}"
puts "  AR Retreats:    #{Retreat.where(country_code: 'AR').count}"
puts "  AR Bookings:    #{Booking.joins(:organization).where(organizations: { country_code: 'AR' }).count}"
puts "  jonaawtf@gmail.com / humana1234"

# =============================================================================
# Subscriptions — give all agency and hotel orgs the monthly plan
# =============================================================================
puts ""
puts "Seeding subscriptions for demo orgs..."

agency_starter = SubscriptionPlan.find_by(name: "Agency Monthly", target_audience: "agency")
hotel_starter  = SubscriptionPlan.find_by(name: "Hotel Monthly", target_audience: "hotel")

if agency_starter
  Organization.where(kind: "agency").find_each do |org|
    next if org.subscriptions.active_or_trialing.exists?
    Subscription.create!(
      organization: org,
      subscription_plan: agency_starter,
      status: "active",
      current_period_start: Date.current,
      current_period_end: Date.current + 30.days
    )
  end
end

if hotel_starter
  Organization.where(kind: "hotel").find_each do |org|
    next if org.subscriptions.active_or_trialing.exists?
    next if org.sponsored?
    Subscription.create!(
      organization: org,
      subscription_plan: hotel_starter,
      status: "active",
      current_period_start: Date.current,
      current_period_end: Date.current + 30.days
    )
  end
end

puts "  Subscriptions:  #{Subscription.count}"
