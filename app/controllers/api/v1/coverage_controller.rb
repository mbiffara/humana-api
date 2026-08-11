module Api
  module V1
    # Powers the dashboard world map: one marker per country with a count of
    # active vs. upcoming experiences and representative coordinates.
    class CoverageController < BaseController
      # GET /api/v1/coverage
      def index
        rows = Experience.published
                         .in_enabled_country
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

        # Hotel-published retreats are a separate catalog — merge their counts
        retreat_rows = Retreat.published
                              .in_enabled_country
                              .joins(:hotel)
                              .group(:country_code, :country)
                              .pluck(
                                :country_code,
                                :country,
                                Arel.sql("COUNT(*)"),
                                Arel.sql("COUNT(*) FILTER (WHERE retreats.status = 'active')"),
                                Arel.sql("AVG(hotels.latitude)"),
                                Arel.sql("AVG(hotels.longitude)")
                              )

        # Hotels per country — use same scope as public hotels endpoint
        hotel_data = ::Hotel.in_enabled_country
                          .where.not(country_code: [nil, ""])
                          .group(:country_code)
                          .pluck(
                            :country_code,
                            Arel.sql("COUNT(*)"),
                            Arel.sql("AVG(latitude)"),
                            Arel.sql("AVG(longitude)")
                          )

        by_code = {}
        (rows + retreat_rows).each do |code, country, total, active, lat, lng|
          marker = by_code[code] ||= {
            country_code: code,
            country: country,
            experiences: 0,
            active: 0,
            upcoming: 0,
            hotels: 0,
            latitude: lat&.to_f,
            longitude: lng&.to_f
          }
          marker[:experiences] += total.to_i
          marker[:active] += active.to_i
          marker[:upcoming] = marker[:experiences] - marker[:active]
          marker[:latitude] ||= lat&.to_f
          marker[:longitude] ||= lng&.to_f
        end

        # Merge hotel counts + coordinates (may include countries with hotels but no experiences)
        hotel_data.each do |code, count, lat, lng|
          marker = by_code[code] ||= {
            country_code: code,
            country: code,
            experiences: 0,
            active: 0,
            upcoming: 0,
            hotels: 0,
            latitude: lat&.to_f,
            longitude: lng&.to_f
          }
          marker[:hotels] = count
          marker[:latitude] ||= lat&.to_f
          marker[:longitude] ||= lng&.to_f
        end

        markers = by_code.values.sort_by { |m| -m[:experiences] }

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
