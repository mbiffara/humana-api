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
  u.name = "HUMANA Operations"
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

puts "Done."
puts "  Organizations: #{Organization.count}"
puts "  Users:         #{User.count}  (login: agent@viajeseter.com / humana1234)"
puts "  Hotels:        #{Hotel.count}"
puts "  Experiences:   #{Experience.count}"
puts "  Clients:       #{Client.count}"
puts "  Bookings:      #{Booking.count}"
