module Api
  module V1
    # Reservations placed by an agency on behalf of its clients, including the
    # commission HUMANA settles back to the agency.
    class BookingsController < BaseController
      before_action :require_agency!
      before_action :set_booking, only: %i[show update verify_checkout]

      # GET /api/v1/bookings?status=confirmed
      def index
        scope = current_organization.bookings
                                    .where.not(status: "pending_payment")
                                    .includes(:hotel, :client, :room_type, :room, :retreat, experience: :hotel)
                                    .order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(client_id: params[:client_id]) if params[:client_id].present?
        if params[:hotel_id].present?
          scope = scope.where(
            "(bookings.experience_id IS NOT NULL AND EXISTS (" \
            "  SELECT 1 FROM experiences WHERE experiences.id = bookings.experience_id AND experiences.hotel_id = :hid" \
            ")) OR (bookings.experience_id IS NULL AND bookings.hotel_id = :hid)",
            hid: params[:hotel_id]
          )
        end

        render json: {
          bookings: paginate(scope).map { |b| ApiSerializers.booking(b) },
          meta: meta_for(scope),
          summary: summary(scope)
        }
      end

      # GET /api/v1/bookings/:id
      def show
        render json: { booking: ApiSerializers.booking(@booking) }
      end

      # POST /api/v1/bookings
      def create
        booking = current_organization.bookings.new(booking_params)
        booking.status = "pending_payment"
        booking.save!

        checkout_url = create_checkout_session(booking)
        render json: {
          booking: ApiSerializers.booking(booking),
          checkout_url: checkout_url
        }, status: :created
      end

      # POST /api/v1/bookings/:id/verify_checkout
      def verify_checkout
        session_id = params[:session_id]
        return render_bad_request("session_id is required") unless session_id.present?

        session = Stripe::Checkout::Session.retrieve(session_id)
        raise ActiveRecord::RecordNotFound, "Session not completed" unless session.status == "complete"

        booking_id = session.metadata&.booking_id
        raise ActiveRecord::RecordNotFound, "Booking mismatch" unless booking_id.to_s == @booking.id.to_s

        # Idempotent — already confirmed is fine
        unless @booking.status == "confirmed"
          @booking.update!(status: "confirmed")

          # Client booking → email to client; inventory → email to agency account
          recipient = if @booking.client.present? && @booking.client.email.present?
                        @booking.client.email
                      else
                        current_user.email
                      end
          BookingMailer.confirmation(@booking, recipient_email: recipient).deliver_later

          # Notify the hotel about the new booking
          BookingMailer.hotel_notification(@booking).deliver_later

          # Send receipt to the agency
          BookingMailer.agency_confirmation(@booking).deliver_later
        end

        render json: { booking: ApiSerializers.booking(@booking.reload) }
      end

      # PATCH/PUT /api/v1/bookings/:id  (update status / guests / notes)
      def update
        @booking.update!(update_params)
        render json: { booking: ApiSerializers.booking(@booking) }
      end

      private

      def set_booking
        @booking = current_organization.bookings.includes(:hotel, :client, :room_type, :room, :retreat, experience: :hotel).find(params[:id])
      end

      def booking_params
        params.require(:booking).permit(:experience_id, :hotel_id, :client_id, :room_type_id, :retreat_id, :guests, :notes, :starts_on, :ends_on)
      end

      def update_params
        params.require(:booking).permit(:status, :room_type_id, :guests, :notes, :client_id)
      end

      # Commission and volume totals for the agency's commissions view.
      def summary(scope)
        active = scope.active
        retreat_scope = scope.where("experience_id IS NOT NULL OR retreat_id IS NOT NULL")
        lodging_scope = scope.where(experience_id: nil, retreat_id: nil)
        {
          total: scope.count,
          confirmed: scope.where(status: "confirmed").count,
          retreat_count: retreat_scope.count,
          lodging_count: lodging_scope.count,
          commission_cents: active.sum(:commission_cents),
          volume_cents: active.sum(:amount_cents)
        }
      end

      def create_checkout_session(booking)
        customer = find_or_create_stripe_customer
        description = booking.experience&.title || booking.retreat&.name || booking.hotel&.name || "Booking"

        session = Stripe::Checkout::Session.create(
          customer: customer.id,
          mode: "payment",
          line_items: [{
            price_data: {
              currency: (booking.currency || "usd").downcase,
              unit_amount: booking.amount_cents,
              product_data: { name: "#{description} \u2014 #{booking.reference}" }
            },
            quantity: 1
          }],
          success_url: "#{web_url}/agency/bookings?stripe=success&session_id={CHECKOUT_SESSION_ID}&booking_id=#{booking.id}",
          cancel_url: "#{web_url}/agency/bookings?stripe=cancelled",
          metadata: {
            organization_id: current_organization.id,
            booking_id: booking.id,
            booking_reference: booking.reference
          }
        )

        session.url
      end

      def find_or_create_stripe_customer
        # Reuse existing customer from previous subscriptions
        existing_sub = current_organization.subscriptions
                         .where.not(stripe_customer_id: [nil, ""])
                         .order(created_at: :desc).first
        if existing_sub
          begin
            return Stripe::Customer.retrieve(existing_sub.stripe_customer_id)
          rescue Stripe::InvalidRequestError
            # Customer no longer exists — fall through
          end
        end

        Stripe::Customer.create(
          email: current_organization.contact_email || current_user.email,
          name: current_organization.name,
          metadata: { organization_id: current_organization.id }
        )
      end

      def web_url
        ENV.fetch("HUMANA_WEB_URL", "http://localhost:3000")
      end
    end
  end
end
