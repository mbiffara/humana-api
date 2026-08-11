# Sends branded booking emails:
# - `confirmation` → to the client (or agency account for inventory bookings)
# - `hotel_notification` → to the hotel, alerting them of a new booking
# Language is determined by the recipient organization's country code.
class BookingMailer < ApplicationMailer
  SPANISH_COUNTRIES = %w[MX AR ES CO CL PE VE EC UY PY BO CR PA DO GT HN SV NI CU PR].freeze
  PORTUGUESE_COUNTRIES = %w[BR PT AO MZ].freeze

  TRANSLATIONS = {
    "en" => {
      subject: "Booking Confirmed",
      eyebrow: "BOOKING CONFIRMATION",
      title: "Your reservation has been confirmed.",
      greeting: "Hello %{name},",
      body: "Great news! Your wellness retreat booking has been confirmed and paid. Below you'll find the details of your reservation.",
      reference_label: "Reference",
      hotel_label: "Hotel",
      experience_label: "Experience",
      room_label: "Room Type",
      dates_label: "Dates",
      guests_label: "Guests",
      total_label: "Total Paid",
      booked_by_label: "Booked by",
      footer_brand: "HUMANA Global \u00B7 Wellness Tourism Network",
      footer_line: "This confirmation was sent to",
      footer_auto: "This is an automated message. Please contact your travel agency for any questions.",
    },
    "es" => {
      subject: "Reserva Confirmada",
      eyebrow: "CONFIRMACI\u00D3N DE RESERVA",
      title: "Tu reserva ha sido confirmada.",
      greeting: "Hola %{name},",
      body: "\u00A1Buenas noticias! Tu reserva de retiro de bienestar ha sido confirmada y pagada. A continuaci\u00F3n encontrar\u00E1s los detalles de tu reservaci\u00F3n.",
      reference_label: "Referencia",
      hotel_label: "Hotel",
      experience_label: "Experiencia",
      room_label: "Tipo de Habitaci\u00F3n",
      dates_label: "Fechas",
      guests_label: "Hu\u00E9spedes",
      total_label: "Total Pagado",
      booked_by_label: "Reservado por",
      footer_brand: "HUMANA Global \u00B7 Red de Turismo de Bienestar",
      footer_line: "Esta confirmaci\u00F3n fue enviada a",
      footer_auto: "Este es un mensaje autom\u00E1tico. Contacta a tu agencia de viajes para cualquier consulta.",
    },
    "pt" => {
      subject: "Reserva Confirmada",
      eyebrow: "CONFIRMA\u00C7\u00C3O DE RESERVA",
      title: "Sua reserva foi confirmada.",
      greeting: "Ol\u00E1 %{name},",
      body: "\u00D3timas not\u00EDcias! Sua reserva de retiro de bem-estar foi confirmada e paga. Abaixo voc\u00EA encontrar\u00E1 os detalhes da sua reserva.",
      reference_label: "Refer\u00EAncia",
      hotel_label: "Hotel",
      experience_label: "Experi\u00EAncia",
      room_label: "Tipo de Quarto",
      dates_label: "Datas",
      guests_label: "H\u00F3spedes",
      total_label: "Total Pago",
      booked_by_label: "Reservado por",
      footer_brand: "HUMANA Global \u00B7 Rede de Turismo de Bem-estar",
      footer_line: "Esta confirma\u00E7\u00E3o foi enviada para",
      footer_auto: "\u00C9 uma mensagem autom\u00E1tica. Entre em contato com sua ag\u00EAncia de viagens para qualquer d\u00FAvida.",
    },
  }.freeze

  AGENCY_TRANSLATIONS = {
    "en" => {
      subject: "Booking Confirmed",
      eyebrow: "BOOKING RECEIPT",
      title: "Your booking has been confirmed.",
      greeting: "Hello %{name},",
      body: "Your booking has been processed and confirmed. Below is a summary of the reservation for your records.",
      reference_label: "Reference",
      client_label: "Client",
      hotel_label: "Hotel",
      experience_label: "Experience",
      room_label: "Room Type",
      dates_label: "Dates",
      nights_label: "Nights",
      guests_label: "Guests",
      total_label: "Total Charged",
      commission_label: "Your Commission",
      net_hotel_label: "Net to Hotel",
      footer_brand: "HUMANA Global \u00B7 Wellness Tourism Network",
      footer_line: "This receipt was sent to",
      footer_auto: "This is an automated message. Visit your HUMANA dashboard to manage your bookings.",
    },
    "es" => {
      subject: "Reserva Confirmada",
      eyebrow: "COMPROBANTE DE RESERVA",
      title: "Tu reserva ha sido confirmada.",
      greeting: "Hola %{name},",
      body: "Tu reserva ha sido procesada y confirmada. A continuaci\u00F3n encontrar\u00E1s un resumen de la reservaci\u00F3n para tus registros.",
      reference_label: "Referencia",
      client_label: "Cliente",
      hotel_label: "Hotel",
      experience_label: "Experiencia",
      room_label: "Tipo de Habitaci\u00F3n",
      dates_label: "Fechas",
      nights_label: "Noches",
      guests_label: "Hu\u00E9spedes",
      total_label: "Total Cobrado",
      commission_label: "Tu Comisi\u00F3n",
      net_hotel_label: "Neto al Hotel",
      footer_brand: "HUMANA Global \u00B7 Red de Turismo de Bienestar",
      footer_line: "Este comprobante fue enviado a",
      footer_auto: "Este es un mensaje autom\u00E1tico. Visita tu panel de HUMANA para gestionar tus reservas.",
    },
    "pt" => {
      subject: "Reserva Confirmada",
      eyebrow: "COMPROVANTE DE RESERVA",
      title: "Sua reserva foi confirmada.",
      greeting: "Ol\u00E1 %{name},",
      body: "Sua reserva foi processada e confirmada. Abaixo est\u00E1 um resumo da reserva para seus registros.",
      reference_label: "Refer\u00EAncia",
      client_label: "Cliente",
      hotel_label: "Hotel",
      experience_label: "Experi\u00EAncia",
      room_label: "Tipo de Quarto",
      dates_label: "Datas",
      nights_label: "Noites",
      guests_label: "H\u00F3spedes",
      total_label: "Total Cobrado",
      commission_label: "Sua Comiss\u00E3o",
      net_hotel_label: "L\u00EDquido ao Hotel",
      footer_brand: "HUMANA Global \u00B7 Rede de Turismo de Bem-estar",
      footer_line: "Este comprovante foi enviado para",
      footer_auto: "\u00C9 uma mensagem autom\u00E1tica. Visite seu painel HUMANA para gerenciar suas reservas.",
    },
  }.freeze

  HOTEL_TRANSLATIONS = {
    "en" => {
      subject: "New Booking Received",
      eyebrow: "NEW BOOKING",
      title: "You have a new reservation.",
      greeting: "Hello %{name},",
      body: "A new booking has been confirmed and paid through the HUMANA network. Here are the details:",
      reference_label: "Reference",
      agency_label: "Booked by",
      experience_label: "Experience",
      room_label: "Room Type",
      dates_label: "Dates",
      nights_label: "Nights",
      guests_label: "Guests",
      total_label: "Booking Total",
      net_label: "Your Net Revenue",
      contact_label: "Agency Contact",
      email_label: "Email",
      phone_label: "Phone",
      footer_brand: "HUMANA Global \u00B7 Wellness Tourism Network",
      footer_line: "This notification was sent to",
      footer_auto: "This is an automated message. Log in to your HUMANA dashboard to manage this booking.",
    },
    "es" => {
      subject: "Nueva Reserva Recibida",
      eyebrow: "NUEVA RESERVA",
      title: "Tienes una nueva reserva.",
      greeting: "Hola %{name},",
      body: "Se ha confirmado y pagado una nueva reserva a trav\u00E9s de la red HUMANA. Estos son los detalles:",
      reference_label: "Referencia",
      agency_label: "Reservado por",
      experience_label: "Experiencia",
      room_label: "Tipo de Habitaci\u00F3n",
      dates_label: "Fechas",
      nights_label: "Noches",
      guests_label: "Hu\u00E9spedes",
      total_label: "Total de la Reserva",
      net_label: "Tu Ingreso Neto",
      contact_label: "Contacto de la Agencia",
      email_label: "Email",
      phone_label: "Tel\u00E9fono",
      footer_brand: "HUMANA Global \u00B7 Red de Turismo de Bienestar",
      footer_line: "Esta notificaci\u00F3n fue enviada a",
      footer_auto: "Este es un mensaje autom\u00E1tico. Inicia sesi\u00F3n en tu panel de HUMANA para gestionar esta reserva.",
    },
    "pt" => {
      subject: "Nova Reserva Recebida",
      eyebrow: "NOVA RESERVA",
      title: "Voc\u00EA tem uma nova reserva.",
      greeting: "Ol\u00E1 %{name},",
      body: "Uma nova reserva foi confirmada e paga atrav\u00E9s da rede HUMANA. Aqui est\u00E3o os detalhes:",
      reference_label: "Refer\u00EAncia",
      agency_label: "Reservado por",
      experience_label: "Experi\u00EAncia",
      room_label: "Tipo de Quarto",
      dates_label: "Datas",
      nights_label: "Noites",
      guests_label: "H\u00F3spedes",
      total_label: "Total da Reserva",
      net_label: "Sua Receita L\u00EDquida",
      contact_label: "Contato da Ag\u00EAncia",
      email_label: "Email",
      phone_label: "Telefone",
      footer_brand: "HUMANA Global \u00B7 Rede de Turismo de Bem-estar",
      footer_line: "Esta notifica\u00E7\u00E3o foi enviada para",
      footer_auto: "\u00C9 uma mensagem autom\u00E1tica. Fa\u00E7a login no painel HUMANA para gerenciar esta reserva.",
    },
  }.freeze

  # ── Confirmation email (to client or agency account) ──────────────────

  def confirmation(booking, recipient_email:)
    @booking = booking
    @client = booking.client
    @organization = booking.organization
    @experience = booking.experience
    @hotel = booking.experience&.hotel || booking.hotel
    @room_type = booking.room_type
    @reference = booking.reference
    @recipient_email = recipient_email

    @locale = locale_for_country_code(@organization.country_code)
    @t = TRANSLATIONS[@locale] || TRANSLATIONS["en"]

    @client_name = @client&.name || @organization.name
    @greeting = @t[:greeting] % { name: @client_name }
    @hotel_name = @hotel&.name
    @experience_title = @experience&.title
    @room_name = @room_type&.name
    @dates = format_dates(booking.starts_on, booking.ends_on)
    @guests = booking.guests
    @total = format_amount(booking.amount_cents, booking.currency)
    @agency_name = @organization.name

    logo_path = Rails.root.join("app/assets/images/humana-logo-email.png")
    attachments.inline["humana-logo.png"] = File.read(logo_path)

    mail(
      to: @recipient_email,
      subject: "\u2705 #{@t[:subject]} \u2014 #{@reference}",
    )
  end

  # ── Agency receipt email (confirmation for the agency) ────────────────

  def agency_confirmation(booking)
    @booking = booking
    @client = booking.client
    @organization = booking.organization
    @experience = booking.experience
    @hotel = booking.experience&.hotel || booking.hotel
    @room_type = booking.room_type
    @reference = booking.reference

    @recipient_email = @organization.contact_email ||
                       @organization.users.find_by(role: "owner")&.email
    return unless @recipient_email

    @locale = locale_for_country_code(@organization.country_code)
    @t = AGENCY_TRANSLATIONS[@locale] || AGENCY_TRANSLATIONS["en"]

    @agency_name = @organization.name
    @greeting = @t[:greeting] % { name: @agency_name }
    @client_name = @client&.name
    @hotel_name = @hotel&.name
    @experience_title = @experience&.title
    @room_name = @room_type&.name
    @dates = format_dates(booking.starts_on, booking.ends_on)
    @nights = compute_nights(booking.starts_on, booking.ends_on)
    @guests = booking.guests
    @total = format_amount(booking.amount_cents, booking.currency)
    @commission = format_amount(booking.commission_cents, booking.currency)
    @net_hotel_cents = booking.amount_cents - booking.commission_cents
    @net_hotel = format_amount(@net_hotel_cents, booking.currency)

    logo_path = Rails.root.join("app/assets/images/humana-logo-email.png")
    attachments.inline["humana-logo.png"] = File.read(logo_path)

    mail(
      to: @recipient_email,
      subject: "\u{1F4CB} #{@t[:subject]} \u2014 #{@reference}",
    )
  end

  # ── Hotel notification email (new booking alert) ──────────────────────

  def hotel_notification(booking)
    @booking = booking
    @organization = booking.organization # the agency
    @experience = booking.experience
    @hotel = booking.experience&.hotel || booking.hotel
    @room_type = booking.room_type
    @reference = booking.reference

    return unless @hotel # safety: can't notify without a hotel

    @recipient_email = @hotel.contact_email || @hotel.organization.contact_email ||
                       @hotel.organization.users.find_by(role: "owner")&.email
    return unless @recipient_email # no email to send to

    @locale = locale_for_country_code(@hotel.country_code)
    @t = HOTEL_TRANSLATIONS[@locale] || HOTEL_TRANSLATIONS["en"]

    @hotel_name = @hotel.name
    @greeting = @t[:greeting] % { name: @hotel_name }
    @agency_name = @organization.name
    @agency_email = @organization.contact_email || @organization.users.find_by(role: "owner")&.email
    @agency_phone = @organization.phone
    @experience_title = @experience&.title
    @room_name = @room_type&.name
    @dates = format_dates(booking.starts_on, booking.ends_on)
    @nights = compute_nights(booking.starts_on, booking.ends_on)
    @guests = booking.guests
    @total = format_amount(booking.amount_cents, booking.currency)
    @net_cents = booking.amount_cents - booking.commission_cents
    @net = format_amount(@net_cents, booking.currency)

    logo_path = Rails.root.join("app/assets/images/humana-logo-email.png")
    attachments.inline["humana-logo.png"] = File.read(logo_path)

    mail(
      to: @recipient_email,
      subject: "\u{1F4E9} #{@t[:subject]} \u2014 #{@reference}",
    )
  end

  private

  def locale_for_country_code(code)
    code = code.to_s.upcase
    if SPANISH_COUNTRIES.include?(code)
      "es"
    elsif PORTUGUESE_COUNTRIES.include?(code)
      "pt"
    else
      "en"
    end
  end

  def format_dates(starts_on, ends_on)
    return "\u2014" unless starts_on && ends_on

    "#{starts_on.strftime('%b %d, %Y')} \u2013 #{ends_on.strftime('%b %d, %Y')}"
  end

  def format_amount(cents, currency)
    formatted = (cents / 100.0).round(2)
    "#{currency&.upcase || 'USD'} #{sprintf('%.2f', formatted)}"
  end

  def compute_nights(starts_on, ends_on)
    return 0 unless starts_on && ends_on

    (ends_on - starts_on).to_i
  end
end
