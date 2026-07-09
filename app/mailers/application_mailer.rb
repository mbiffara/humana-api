class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("RESEND_FROM_EMAIL", "HUMANA <noreply@humana.global>")
  layout "mailer"
end
