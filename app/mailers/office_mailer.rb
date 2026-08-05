# Sends emails from office managers to HUMANA admin (info@humana.global).
# Used for approval requests, general queries, and communication.
class OfficeMailer < ApplicationMailer
  ADMIN_EMAIL = "info@humana.global".freeze

  def contact_admin(office:, sender:, subject:, message:)
    @office = office
    @sender = sender
    @message = message
    @subject_line = subject

    logo_path = Rails.root.join("app/assets/images/humana-logo-email.png")
    attachments.inline["humana-logo.png"] = File.read(logo_path)

    mail(
      to: ADMIN_EMAIL,
      reply_to: sender.email,
      subject: "[Office #{office.country}] #{subject}"
    )
  end
end
