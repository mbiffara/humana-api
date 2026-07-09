# Resend transactional email configuration.
# Set RESEND_API_KEY in your environment to enable email delivery.
if ENV["RESEND_API_KEY"].present?
  Resend.api_key = ENV["RESEND_API_KEY"]
end
