module Api
  module V1
    # Powers the dashboard world map: one marker per country with a count of
    # active vs. upcoming experiences and representative coordinates.
    class CoverageController < BaseController
      # GET /api/v1/coverage
      def index
        rows = Experience.published
                         .joins(:hotel)
                         .group(:country_code, :country)
                         .pluck(
                           :country_code,
                           :country,
                           Arel.sql("COUNT(*)"),
                           Arel.sql("COUNT(*) FILTER (WHERE experiences.status = 'active')"),
                           Arel.sql("AVG(hotels.latitude)"),
                           Arel.sql("AVG(hotels.longitude)")
                         )

        markers = rows.map do |code, country, total, active, lat, lng|
          {
            country_code: code,
            country: country,
            experiences: total.to_i,
            active: active.to_i,
            upcoming: total.to_i - active.to_i,
            latitude: lat&.to_f,
            longitude: lng&.to_f
          }
        end.sort_by { |m| -m[:experiences] }

        render json: {
          markers: markers,
          totals: {
            countries: markers.size,
            experiences: markers.sum { |m| m[:experiences] }
          }
        }
      end
    end
  end
end
