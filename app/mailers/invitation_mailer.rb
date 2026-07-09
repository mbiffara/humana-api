# Sends a branded magic-link email when an admin invites a new user.
# Language is determined by the target organization's country.
class InvitationMailer < ApplicationMailer
  # Country codes → locale mapping
  SPANISH_COUNTRIES = %w[MX AR ES CO CL PE VE EC UY PY BO CR PA DO GT HN SV NI CU PR].freeze
  PORTUGUESE_COUNTRIES = %w[BR PT AO MZ].freeze

  TRANSLATIONS = {
    "en" => {
      subject: "Welcome to HUMANA Global — Invitation",
      eyebrow: "INVITATION TO JOIN",
      title: "You've been invited to the HUMANA network.",
      greeting: "Hello,",
      body: "You've been invited to join our curated wellness tourism network. Accept this invitation to set up your profile and start connecting with hotels and retreats worldwide.",
      invited_by: "Invited by",
      role: "Role",
      organization: "Organization",
      expires_label: "Expires",
      expires_value: "7 days",
      cta: "ACCEPT INVITATION",
      copy_link: "Or copy this link:",
      footer_brand: "HUMANA Global · Wellness Tourism Network",
      footer_sent: "This invitation was sent to",
      footer_ignore: "If you didn't expect this, you can safely ignore it.",
      kind_hotel: "Hotel",
      kind_agency: "Agency",
      kind_office: "Office",
      kind_admin: "Administrator",
    },
    "es" => {
      subject: "Bienvenido a HUMANA Global — Invitación",
      eyebrow: "INVITACIÓN",
      title: "Has sido invitado a la red HUMANA.",
      greeting: "Hola,",
      body: "Has sido invitado a unirte a nuestra red de turismo de bienestar. Acepta esta invitación para configurar tu perfil y comenzar a conectar con hoteles y retiros en todo el mundo.",
      invited_by: "Invitado por",
      role: "Rol",
      organization: "Organización",
      expires_label: "Expira en",
      expires_value: "7 días",
      cta: "ACEPTAR INVITACIÓN",
      copy_link: "O copia este enlace:",
      footer_brand: "HUMANA Global · Red de Turismo de Bienestar",
      footer_sent: "Esta invitación fue enviada a",
      footer_ignore: "Si no la esperabas, puedes ignorarla.",
      kind_hotel: "Hotel",
      kind_agency: "Agencia",
      kind_office: "Oficina",
      kind_admin: "Administrador",
    },
    "pt" => {
      subject: "Bem-vindo à HUMANA Global — Convite",
      eyebrow: "CONVITE",
      title: "Você foi convidado para a rede HUMANA.",
      greeting: "Olá,",
      body: "Você foi convidado a se juntar à nossa rede de turismo de bem-estar. Aceite este convite para configurar seu perfil e começar a se conectar com hotéis e retiros em todo o mundo.",
      invited_by: "Convidado por",
      role: "Função",
      organization: "Organização",
      expires_label: "Expira em",
      expires_value: "7 dias",
      cta: "ACEITAR CONVITE",
      copy_link: "Ou copie este link:",
      footer_brand: "HUMANA Global · Rede de Turismo de Bem-estar",
      footer_sent: "Este convite foi enviado para",
      footer_ignore: "Se você não esperava, pode ignorá-lo.",
      kind_hotel: "Hotel",
      kind_agency: "Agência",
      kind_office: "Escritório",
      kind_admin: "Administrador",
    },
  }.freeze

  def invite(invitation)
    @invitation = invitation
    @magic_link = invitation.magic_link
    @org_name = invitation.organization.name
    @locale = locale_for(invitation.organization)
    @t = TRANSLATIONS[@locale] || TRANSLATIONS["en"]
    @kind_label = @t[:"kind_#{invitation.organization.kind}"] || invitation.organization.kind.humanize
    @inviter_name = invitation.invited_by&.name || "HUMANA"

    # Embed logo as inline attachment (works in all email clients)
    logo_path = Rails.root.join("app/assets/images/humana-logo-email.png")
    attachments.inline["humana-logo.png"] = File.read(logo_path)

    mail(
      to: invitation.email,
      subject: "✨ #{@t[:subject]} — #{@kind_label}",
    )
  end

  private

  def locale_for(organization)
    code = organization.country_code.to_s.upcase
    if SPANISH_COUNTRIES.include?(code)
      "es"
    elsif PORTUGUESE_COUNTRIES.include?(code)
      "pt"
    else
      "en"
    end
  end
end
