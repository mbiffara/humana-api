# Sends a branded password-reset email with a magic link.
# Language is determined by the user's locale setting.
class PasswordResetMailer < ApplicationMailer
  TRANSLATIONS = {
    "en" => {
      subject: "Reset your password",
      eyebrow: "PASSWORD RESET",
      title: "Reset your HUMANA password.",
      greeting: "Hello,",
      body: "We received a request to reset your password. Click the button below to choose a new one. This link will expire in 1 hour.",
      expires_label: "Expires in",
      expires_value: "1 hour",
      cta: "RESET PASSWORD",
      copy_link: "Or copy this link:",
      footer_brand: "HUMANA Global · Wellness Tourism Network",
      footer_sent: "This email was sent to",
      footer_ignore: "If you didn't request this, you can safely ignore it.",
    },
    "es" => {
      subject: "Restablecer tu contraseña",
      eyebrow: "RESTABLECER CONTRASEÑA",
      title: "Restablece tu contraseña de HUMANA.",
      greeting: "Hola,",
      body: "Recibimos una solicitud para restablecer tu contraseña. Haz clic en el botón a continuación para elegir una nueva. Este enlace expirará en 1 hora.",
      expires_label: "Expira en",
      expires_value: "1 hora",
      cta: "RESTABLECER CONTRASEÑA",
      copy_link: "O copia este enlace:",
      footer_brand: "HUMANA Global · Red de Turismo de Bienestar",
      footer_sent: "Este email fue enviado a",
      footer_ignore: "Si no solicitaste esto, puedes ignorarlo.",
    },
    "pt" => {
      subject: "Redefinir sua senha",
      eyebrow: "REDEFINIR SENHA",
      title: "Redefina sua senha do HUMANA.",
      greeting: "Olá,",
      body: "Recebemos uma solicitação para redefinir sua senha. Clique no botão abaixo para escolher uma nova. Este link expirará em 1 hora.",
      expires_label: "Expira em",
      expires_value: "1 hora",
      cta: "REDEFINIR SENHA",
      copy_link: "Ou copie este link:",
      footer_brand: "HUMANA Global · Rede de Turismo de Bem-estar",
      footer_sent: "Este email foi enviado para",
      footer_ignore: "Se você não solicitou isso, pode ignorá-lo.",
    },
  }.freeze

  def reset(user)
    @user = user
    @locale = user.locale || "en"
    @t = TRANSLATIONS[@locale] || TRANSLATIONS["en"]
    @reset_link = "#{ENV.fetch('HUMANA_WEB_URL', 'http://localhost:3000')}/reset-password?token=#{user.password_reset_token}"

    # Embed logo as inline attachment (works in all email clients)
    logo_path = Rails.root.join("app/assets/images/humana-logo-email.png")
    attachments.inline["humana-logo.png"] = File.read(logo_path)

    mail(
      to: user.email,
      subject: "🔒 #{@t[:subject]} — HUMANA",
    )
  end
end
