# Plain-Ruby serializers that turn models into the JSON shapes the Next.js
# front-end consumes. Kept dependency-free and explicit on purpose.
module ApiSerializers
  module_function

  def organization(org, include_onboarding: false)
    return nil unless org

    data = {
      id: org.id,
      name: org.name,
      kind: org.kind,
      status: org.status,
      city: org.city,
      country: org.country,
      country_code: org.country_code,
      contact_email: org.contact_email,
      website: org.website,
      onboarding_completed: org.onboarding_completed?,
      sponsored: org.sponsored,
      pending_changes: org.pending_changes,
      review_feedback: org.review_feedback,
      review_feedback_at: org.review_feedback_at&.iso8601,
      hotel_id: org.hotel? ? org.hotels.first&.id : nil,
      created_at: org.created_at&.iso8601
    }

    if include_onboarding
      data.merge!(
        address: org.address,
        legal_name: org.legal_name,
        phone: org.phone,
        primary_contact: org.primary_contact,
        tax_id: org.tax_id,
        description: org.description,
        logo_url: org.logo_url,
        specialties: org.specialties,
        onboarding_completed_at: org.onboarding_completed_at,
        bank_account_holder: org.bank_account_holder,
        bank_iban: org.bank_iban,
        bank_swift: org.bank_swift,
        bank_currency: org.bank_currency,
        bank_country: org.bank_country,
        bank_status: org.bank_status,
      )
    end

    data
  end

  def user(user)
    return nil unless user

    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      status: user.status,
      locale: user.locale,
      phone: user.phone,
      platform_admin: user.platform_admin?,
      last_login_at: user.last_login_at,
      created_at: user.created_at,
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

  def hotel_full(hotel, active_room_types_only: false)
    return nil unless hotel

    base = hotel(hotel)
    rts = active_room_types_only ? hotel.room_types.by_status("active").ordered : hotel.room_types.ordered
    base.merge(
      description: hotel.description,
      address: hotel.try(:address),
      postal_code: hotel.try(:postal_code),
      phone: hotel.phone,
      stars: hotel.stars,
      total_rooms: hotel.total_rooms,
      check_in_time: hotel.check_in_time,
      check_out_time: hotel.check_out_time,
      logo_url: hotel.logo_url,
      website: hotel.website,
      contact_email: hotel.contact_email,
      room_types: rts.map { |rt| room_type(rt, include_details: true) },
      amenities: hotel.hotel_amenities.order(:category, :position).map { |a|
        { id: a.id, name: a.name, category: a.category, icon: a.icon, position: a.position, featured: a.featured }
      },
      images: hotel.hotel_images.order(:position).map { |i|
        { id: i.id, image_url: i.image_url, category: i.category, position: i.position, is_cover: i.is_cover, alt_text: i.alt_text }
      }
    )
  end

  # `include_commission` is false for public endpoints — commission data is
  # B2B-internal and must not be exposed to unauthenticated consumers.
  def experience(exp, include_hotel: true, include_commission: true)
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
      capacity: exp.capacity,
      image_url: exp.image_url
    }
    if include_commission
      data[:commission_rate] = exp.commission_rate.to_f
      data[:commission_percent] = exp.commission_percent
    end
    data[:hotel] = hotel(exp.hotel) if include_hotel
    data
  end

  def client(client, include_bookings: false)
    return nil unless client

    data = {
      id: client.id,
      name: client.name,
      email: client.email,
      phone: client.phone,
      notes: client.notes,
      created_at: client.created_at
    }

    if include_bookings
      data[:booking_count] = client.bookings.size
      data[:bookings] = client.bookings.order(created_at: :desc).limit(10).map { |b|
        { id: b.id, reference: b.reference, status: b.status, created_at: b.created_at }
      }
    end

    data
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
      room_type: room_type(booking.room_type),
      room: room(booking.room),
      created_at: booking.created_at
    }
    data[:experience] = experience(booking.experience) if include_experience
    data[:hotel] = hotel(booking.hotel) if booking.hotel_id && !booking.experience_id
    data
  end

  def country(c)
    return nil unless c

    {
      id: c.id,
      name: c.name,
      code: c.code,
      flag_emoji: c.flag_emoji,
      status: c.status,
      enabled: c.enabled,
      region: c.region,
      currency_code: c.currency_code,
      timezone: c.timezone
    }
  end

  def platform_setting(ps)
    return nil unless ps

    {
      id: ps.id,
      platform_name: ps.platform_name,
      support_email: ps.support_email,
      default_currency: ps.default_currency,
      default_language: ps.default_language,
      agency_commission_rate: ps.agency_commission_rate.to_f,
      agency_commission_percent: ps.agency_commission_percent,
      office_fee_rate: ps.office_fee_rate.to_f,
      office_fee_percent: ps.office_fee_percent,
      hotel_net_rate: ps.hotel_net_rate.to_f,
      terms_url: ps.terms_url,
      privacy_url: ps.privacy_url,
      logo_url: ps.logo_url
    }
  end

  def room_type(rt, include_details: false)
    return nil unless rt

    data = {
      id: rt.id,
      hotel_id: rt.hotel_id,
      name: rt.name,
      category: rt.category,
      status: rt.status,
      capacity: rt.capacity,
      area_sqm: rt.area_sqm&.to_f,
      price_per_night_cents: rt.price_per_night_cents,
      price_per_night: rt.price_per_night,
      currency: rt.currency,
      description: rt.description,
      image_url: rt.image_url,
      total_rooms: rt.total_rooms,
      position: rt.position,
      bed_type: rt.bed_type,
      view_type: rt.view_type,
      amenities_list: rt.amenities
    }

    if include_details
      data[:images] = rt.room_images.ordered.map { |img| room_image(img) }
      data[:rate_tiers] = rt.room_rate_tiers.ordered.map { |tier| room_rate_tier(tier) }
    end

    data
  end

  def room_image(img)
    return nil unless img

    {
      id: img.id,
      image_url: img.image_url,
      position: img.position,
      alt_text: img.alt_text,
      is_primary: img.is_primary
    }
  end

  def room_rate_tier(tier)
    return nil unless tier

    {
      id: tier.id,
      min_rooms: tier.min_rooms,
      starts_on: tier.starts_on,
      ends_on: tier.ends_on,
      price_per_night_cents: tier.price_per_night_cents,
      price_per_night: tier.price_per_night
    }
  end

  def inventory_block(block)
    return nil unless block

    {
      id: block.id,
      organization_id: block.organization_id,
      hotel_id: block.hotel_id,
      room_type_id: block.room_type_id,
      room_type: room_type(block.room_type),
      hotel: hotel(block.hotel),
      total_rooms: block.total_rooms,
      available_rooms: block.available_rooms,
      starts_on: block.starts_on,
      ends_on: block.ends_on,
      cost_per_night_cents: block.cost_per_night_cents,
      cost_per_night: block.cost_per_night,
      currency: block.currency,
      status: block.status
    }
  end

  def availability_block(block)
    return nil unless block

    {
      id: block.id,
      hotel_id: block.hotel_id,
      room_type_id: block.room_type_id,
      starts_on: block.starts_on,
      ends_on: block.ends_on,
      units: block.units,
      reason: block.reason
    }
  end

  def room(room)
    return nil unless room

    {
      id: room.id,
      hotel_id: room.hotel_id,
      room_type_id: room.room_type_id,
      number: room.number,
      status: room.status,
      auto_generated: room.auto_generated,
      notes: room.notes
    }
  end

  # Full retreat with nested day-by-day program, facilitators, inclusions,
  # pricing tiers, and gallery. Pass include_details: false for list views.
  # all_pricing: management views (hotel editor, admin review) see pricing for
  # every room type; discovery/booking consumers only see room types that are
  # open for sale (active).
  def retreat(r, include_details: true, include_commission: true, all_pricing: false)
    return nil unless r

    data = {
      id: r.id,
      name: r.name,
      slug: r.slug,
      retreat_type: r.retreat_type,
      status: r.status,
      duration_nights: r.duration_nights,
      starts_on: r.starts_on,
      ends_on: r.ends_on,
      capacity: r.capacity,
      language: r.language,
      description: r.description,
      short_description: r.short_description,
      location: r.location,
      country: r.country,
      country_code: r.country_code,
      min_price_cents: r.min_price_cents,
      min_price: r.min_price,
      currency: r.currency,
      cover_image_url: r.cover_image_url,
      featured: r.featured,
      certified: r.certified,
      published_at: r.published_at,
      created_by_type: r.created_by_type,
      hotel: hotel(r.hotel),
      created_at: r.created_at
    }

    if include_commission
      data[:commission_rate] = r.commission_rate.to_f
      data[:commission_percent] = r.commission_percent
    end

    if include_details
      data[:days] = r.retreat_days.ordered.map { |d| retreat_day(d) }
      data[:facilitators] = r.retreat_facilitators.ordered.map { |f| retreat_facilitator(f) }
      data[:inclusions] = r.retreat_inclusions.ordered.map { |i| retreat_inclusion(i) }
      pricings = r.retreat_pricings.includes(:room_type)
      pricings = pricings.select { |p| p.room_type&.status == "active" } unless all_pricing
      data[:pricing] = pricings.map { |p| retreat_pricing(p) }
      data[:images] = r.retreat_images.ordered.map { |img| retreat_image(img) }
    end

    data
  end

  def retreat_day(d)
    return nil unless d

    {
      id: d.id,
      day_number: d.day_number,
      title: d.title,
      description: d.description,
      activities: d.retreat_activities.ordered.map { |a| retreat_activity(a) }
    }
  end

  def retreat_activity(a)
    return nil unless a

    {
      id: a.id,
      name: a.name,
      time: a.time,
      duration_minutes: a.duration_minutes,
      position: a.position,
      description: a.description,
      category: a.category,
      icon: a.icon
    }
  end

  def retreat_facilitator(f)
    return nil unless f

    {
      id: f.id,
      name: f.name,
      role: f.role,
      specialty: f.specialty,
      avatar_url: f.avatar_url,
      bio: f.bio,
      position: f.position
    }
  end

  def retreat_inclusion(i)
    return nil unless i

    {
      id: i.id,
      name: i.name,
      category: i.category,
      icon: i.icon,
      position: i.position
    }
  end

  def retreat_pricing(p)
    return nil unless p

    {
      id: p.id,
      room_type: room_type(p.room_type),
      price_per_guest_cents: p.price_per_guest_cents,
      price_per_guest: p.price_per_guest,
      currency: p.currency,
      occupancy_label: p.occupancy_label,
      max_guests: p.max_guests
    }
  end

  def retreat_image(img)
    return nil unless img

    {
      id: img.id,
      image_url: img.image_url,
      position: img.position,
      alt_text: img.alt_text,
      is_cover: img.is_cover
    }
  end

  def subscription_plan(sp)
    return nil unless sp

    {
      id: sp.id,
      name: sp.name,
      slug: sp.slug,
      price_cents: sp.price_cents,
      price: sp.price,
      currency: sp.currency,
      billing_interval: sp.billing_interval,
      features: sp.features,
      commission_rate: sp.commission_rate.to_f,
      commission_percent: sp.commission_percent,
      stripe_price_id: sp.stripe_price_id,
      active: sp.active,
      trial_days: sp.trial_days,
      target_audience: sp.target_audience,
      position: sp.position
    }
  end

  def subscription(sub)
    return nil unless sub

    {
      id: sub.id,
      status: sub.status,
      stripe_subscription_id: sub.stripe_subscription_id,
      trial_ends_at: sub.trial_ends_at,
      current_period_start: sub.current_period_start,
      current_period_end: sub.current_period_end,
      cancelled_at: sub.cancelled_at,
      cancel_reason: sub.cancel_reason,
      plan: subscription_plan(sub.subscription_plan),
      organization: organization(sub.organization),
      created_at: sub.created_at
    }
  end

  def stripe_connect_account(sca)
    return nil unless sca

    {
      id: sca.id,
      stripe_account_id: sca.stripe_account_id,
      onboarding_status: sca.onboarding_status,
      mrr_cents: sca.mrr_cents,
      mrr: sca.mrr,
      currency: sca.currency,
      payouts_enabled: sca.payouts_enabled,
      charges_enabled: sca.charges_enabled,
      onboarding_completed_at: sca.onboarding_completed_at,
      organization: organization(sca.organization)
    }
  end

  # A booking on this agency's retreat, made by another agency.
  def billing_sale(b)
    return nil unless b

    {
      id: b.id,
      reference: b.reference,
      status: b.status,
      guests: b.guests,
      starts_on: b.starts_on,
      ends_on: b.ends_on,
      amount_cents: b.amount_cents,
      amount: b.amount,
      currency: b.currency,
      commission_cents: b.commission_cents,
      commission: b.commission,
      retreat_name: b.retreat&.name,
      buying_agency: b.organization&.name,
      client_name: b.client&.name,
      room_type: room_type(b.room_type),
      hotel_name: b.hotel&.name || b.experience&.hotel&.name,
      created_at: b.created_at
    }
  end
end
