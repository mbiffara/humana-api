module Api
  module V1
    module Office
      class RevenueController < BaseController
        # GET /api/v1/office/revenue
        def show
          confirmed = regional_bookings.where(status: "confirmed")
          total_volume = confirmed.sum(:amount_cents)

          # Monthly breakdown (last 12 months)
          months = (0..11).map { |i| Date.current.beginning_of_month - i.months }
          monthly = months.reverse.map do |month|
            month_bookings = confirmed.where(created_at: month.beginning_of_month..month.end_of_month)
            vol = month_bookings.sum(:amount_cents)
            {
              month: month.strftime("%Y-%m"),
              label: month.strftime("%b %Y"),
              volume_cents: vol,
              office_revenue_cents: (vol * office_fee_rate).round,
              booking_count: month_bookings.count
            }
          end

          # Top hotels by volume (via bookings on their experiences)
          top_hotels = ::Hotel
            .joins(experiences: :bookings)
            .where(id: regional_hotels.select(:id))
            .where(bookings: { status: "confirmed" })
            .select("hotels.id, hotels.name, hotels.city, hotels.country, SUM(bookings.amount_cents) AS total_volume")
            .group("hotels.id, hotels.name, hotels.city, hotels.country")
            .order("total_volume DESC")
            .limit(10)
            .map { |h| { id: h.id, name: h.name, city: h.city, country: h.country, volume_cents: h.total_volume.to_i } }

          # Top agencies by volume
          top_agencies = Organization
            .joins(:bookings)
            .where(id: regional_agency_organizations.select(:id))
            .where(bookings: { status: "confirmed" })
            .select("organizations.id, organizations.name, organizations.city, SUM(bookings.amount_cents) AS total_volume")
            .group("organizations.id, organizations.name, organizations.city")
            .order("total_volume DESC")
            .limit(10)
            .map { |o| { id: o.id, name: o.name, city: o.city, volume_cents: o.total_volume.to_i } }

          render json: {
            revenue: {
              total_volume_cents: total_volume,
              total_office_revenue_cents: (total_volume * office_fee_rate).round,
              office_fee_rate: office_fee_rate.to_f,
              monthly: monthly,
              top_hotels: top_hotels,
              top_agencies: top_agencies
            }
          }
        end
      end
    end
  end
end
