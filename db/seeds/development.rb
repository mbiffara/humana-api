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
                   { name: "Check-in & Welcome Tea", time: "15:00", duration_minutes: 60, position: 0, category: "logistics" },
                   { name: "Opening Circle", time: "17:00", duration_minutes: 90, position: 1, category: "ceremony" },
                   { name: "Welcome Dinner", time: "19:30", duration_minutes: 90, position: 2, category: "dining" },
                 ]
               when 6
                 [
                   { name: "Sunrise Meditation", time: "07:00", duration_minutes: 45, position: 0, category: "meditation" },
                   { name: "Closing Ceremony", time: "09:00", duration_minutes: 120, position: 1, category: "ceremony" },
                   { name: "Farewell Brunch", time: "11:30", duration_minutes: 60, position: 2, category: "dining" },
                 ]
               else
                 [
                   { name: "Morning Vinyasa Flow", time: "07:00", duration_minutes: 90, position: 0, category: "yoga" },
                   { name: "Guided Meditation", time: "09:00", duration_minutes: 45, position: 1, category: "meditation" },
                   { name: "Workshop: #{["Breathwork", "Ayurveda", "Sound Healing", "Yin Yoga", "Journaling"][i - 1]}", time: "11:00", duration_minutes: 120, position: 2, category: "workshop" },
                   { name: "Free Time / Spa", time: "14:00", duration_minutes: 180, position: 3, category: "leisure" },
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
  { name: "Full Board (organic meals)", category: "dining", icon: "restaurant", position: 1 },
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
  kind: "retreat",
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
  rt.category = "cabana"
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
  { name: "Cenote Access", category: "nature", icon: "cenote", position: 1, featured: true },
  { name: "Beach Club", category: "leisure", icon: "beach", position: 2, featured: true },
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
    { name: "Cenote Dive", time: "11:00", duration_minutes: 120, position: 2, category: "nature" },
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
  { name: "Full Board (local cuisine)", category: "dining", icon: "restaurant", position: 1 },
  { name: "Cenote & Beach Access", category: "nature", icon: "cenote", position: 2 },
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
  kind: "retreat",
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
puts ""
puts "Login credentials:"
puts "  admin@humana.global / humana1234"
puts "  hotel@aia.com / humana1234"
puts "  hotel@santuariodelsol.mx / humana1234"
puts "  agent@viajeseter.com / humana1234"
