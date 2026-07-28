# Hotel workspace dashboard (HT-02). Aggregates the numbers the landing
# screen needs in one call: occupancy, revenue, upcoming check-ins, and the
# retreat program summary. Occupancy compares the last 30 days against the
# 30 days before; revenue compares the current calendar month to the last.
module Api
  module V1
    module Hotel
      class DashboardController < BaseController
        OCCUPANCY_WINDOW_DAYS = 30
        UPCOMING_WINDOW_DAYS = 7
        CHECK_INS_LIMIT = 4
        RETREAT_ITEMS_LIMIT = 3

        def show
          today = Date.current
          render json: {
            dashboard: {
              hotel: hotel_summary,
              occupancy: occupancy(today),
              revenue: revenue(today),
              upcoming: upcoming(today),
              next_check_ins: next_check_ins(today),
              retreats: retreats_summary(today)
            }
          }
        end

        private

        def hotel_summary
          {
            name: current_hotel.name,
            city: current_hotel.city,
            country: current_hotel.country,
            rooms_total: current_hotel.rooms.count,
            member_since: current_organization.created_at.to_date
          }
        end

        def occupancy(today)
          current_from = today - (OCCUPANCY_WINDOW_DAYS - 1)
          previous_from = current_from - OCCUPANCY_WINDOW_DAYS

          {
            rate: occupancy_rate(current_from, today),
            previous_rate: occupancy_rate(previous_from, current_from - 1)
          }
        end

        # Booked room-nights over operational room-nights for the window.
        def occupancy_rate(from, to)
          operational = current_hotel.rooms.where(status: "available").count
          return 0.0 if operational.zero?

          capacity = operational * ((to - from).to_i + 1)
          booked = hotel_bookings
                   .where.not(starts_on: nil).where.not(ends_on: nil)
                   .where("bookings.starts_on <= ? AND bookings.ends_on > ?", to, from)
                   .sum { |b| ([b.ends_on, to + 1].min - [b.starts_on, from].max).to_i.clamp(0, capacity) }
          (booked.to_f / capacity).clamp(0.0, 1.0).round(4)
        end

        def revenue(today)
          current = month_revenue_cents(today.beginning_of_month, today.end_of_month)
          previous = month_revenue_cents(today.prev_month.beginning_of_month, today.prev_month.end_of_month)

          { current_cents: current, previous_cents: previous, currency: "USD" }
        end

        def month_revenue_cents(from, to)
          hotel_bookings.where(starts_on: from..to).sum(:amount_cents)
        end

        def upcoming(today)
          window = hotel_bookings.where(starts_on: today..(today + UPCOMING_WINDOW_DAYS - 1))
          {
            guests: window.sum(:guests),
            check_ins_today: window.where(starts_on: today).count
          }
        end

        def next_check_ins(today)
          hotel_bookings
            .includes(:client, :room_type, :organization)
            .where("bookings.starts_on >= ?", today)
            .order(:starts_on)
            .limit(CHECK_INS_LIMIT)
            .map do |booking|
              nights = booking.ends_on && booking.starts_on ? (booking.ends_on - booking.starts_on).to_i : nil
              {
                id: booking.id,
                reference: booking.reference,
                starts_on: booking.starts_on,
                days_until: (booking.starts_on - today).to_i,
                guest_name: booking.client&.name,
                room_type: booking.room_type&.name,
                nights: nights,
                agency: booking.organization&.name
              }
            end
        end

        def retreats_summary(today)
          published = current_hotel.retreats.published.to_a
          in_progress, rest = published.partition do |r|
            r.starts_on && r.ends_on && r.starts_on <= today && r.ends_on >= today
          end
          upcoming = rest.select { |r| r.starts_on.nil? || r.starts_on > today }

          items = (in_progress + upcoming.sort_by { |r| r.starts_on || Date.new(9999) })
                  .first(RETREAT_ITEMS_LIMIT)
                  .map do |r|
            {
              id: r.id,
              name: r.name,
              starts_on: r.starts_on,
              ends_on: r.ends_on,
              capacity: r.capacity,
              state: in_progress.include?(r) ? "in_progress" : "upcoming"
            }
          end

          { in_progress: in_progress.size, upcoming: upcoming.size, items: items }
        end

        def hotel_bookings
          ::Booking.active.joins(:experience).where(experiences: { hotel_id: current_hotel.id })
        end
      end
    end
  end
end
