# Plain-Ruby serializers that turn models into the JSON shapes the Next.js
# front-end consumes. Kept dependency-free and explicit on purpose.
module ApiSerializers
  module_function

  def organization(org)
    return nil unless org

    {
      id: org.id,
      name: org.name,
      kind: org.kind,
      status: org.status,
      city: org.city,
      country: org.country,
      country_code: org.country_code,
      website: org.website
    }
  end

  def user(user)
    return nil unless user

    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      locale: user.locale,
      platform_admin: user.platform_admin?,
      last_login_at: user.last_login_at,
      organization: organization(user.organization)
    }
  end

  def hotel(hotel)
    return nil unless hotel

    {
      id: hotel.id,
      name: hotel.name,
      city: hotel.city,
      country: hotel.country,
      country_code: hotel.country_code,
      latitude: hotel.latitude&.to_f,
      longitude: hotel.longitude&.to_f,
      certified: hotel.certified,
      wellness_standard: hotel.wellness_standard
    }
  end

  def experience(exp, include_hotel: true)
    return nil unless exp

    data = {
      id: exp.id,
      slug: exp.slug,
      kind: exp.kind,
      status: exp.status,
      title: exp.title,
      description: exp.description,
      location: exp.location,
      country: exp.country,
      country_code: exp.country_code,
      starts_on: exp.starts_on,
      ends_on: exp.ends_on,
      price_cents: exp.price_cents,
      price: exp.price,
      currency: exp.currency,
      commission_rate: exp.commission_rate.to_f,
      commission_percent: exp.commission_percent,
      capacity: exp.capacity,
      image_url: exp.image_url
    }
    data[:hotel] = hotel(exp.hotel) if include_hotel
    data
  end

  def client(client)
    return nil unless client

    {
      id: client.id,
      name: client.name,
      email: client.email,
      phone: client.phone,
      notes: client.notes,
      created_at: client.created_at
    }
  end

  def booking(booking, include_experience: true)
    return nil unless booking

    data = {
      id: booking.id,
      reference: booking.reference,
      status: booking.status,
      guests: booking.guests,
      starts_on: booking.starts_on,
      ends_on: booking.ends_on,
      amount_cents: booking.amount_cents,
      amount: booking.amount,
      currency: booking.currency,
      commission_cents: booking.commission_cents,
      commission: booking.commission,
      notes: booking.notes,
      client: client(booking.client),
      created_at: booking.created_at
    }
    data[:experience] = experience(booking.experience) if include_experience
    data
  end
end
