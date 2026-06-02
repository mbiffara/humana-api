# Be sure to restart your server when you modify this file.
#
# Cross-Origin Resource Sharing (CORS) for the HUMANA Next.js front-end.
#
# Allowed origins are read from the HUMANA_WEB_ORIGINS env var (comma-separated)
# and fall back to the local Next.js dev server. Tighten this list in production.
#
# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      ENV.fetch("HUMANA_WEB_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000")
        .split(",")
        .map(&:strip)
    )

    resource "*",
      headers: :any,
      expose: %w[Authorization],
      methods: %i[get post put patch delete options head],
      max_age: 600
  end
end
