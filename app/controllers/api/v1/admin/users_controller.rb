# Admin user management — list, inspect, invite, and moderate users.
# Invitation creates a pending user record and sends a magic-link email via Resend.
module Api
  module V1
    module Admin
      class UsersController < BaseController
        before_action :set_user, only: %i[show approve reject send_feedback suspend reactivate destroy]

        # GET /api/v1/admin/users
        # Filters: status, role, kind (org kind), organization_id, q (name/email search)
        def index
          scope = User.joins(:organization).where.not(organizations: { kind: "admin" })
          scope = scope.where(status: params[:status]) if params[:status].present?
          scope = scope.where(role: params[:role]) if params[:role].present?
          scope = scope.where(organizations: { kind: params[:kind] }) if params[:kind].present?
          scope = scope.where(organization_id: params[:organization_id]) if params[:organization_id].present?
          scope = scope.where("users.name ILIKE :q OR users.email ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?

          scope = scope.includes(:organization).order("users.created_at DESC")
          meta = meta_for(scope)

          paginated = paginate(scope)

          # Look up invitations to find who invited each user
          emails = paginated.map(&:email)
          invitations_by_email = Invitation.where(email: emails)
            .includes(invited_by: :organization)
            .index_by(&:email)

          render json: {
            users: paginated.map { |u|
              data = ApiSerializers.user(u).merge(status: u.status)
              inv = invitations_by_email[u.email]
              if inv&.invited_by&.organization
                org = inv.invited_by.organization
                data[:invited_by_organization] = {
                  id: org.id,
                  name: org.name,
                  kind: org.kind
                }
              end
              if inv
                data[:invitation_id] = inv.id
                data[:invitation_accepted] = inv.accepted_at.present?
                data[:invited_at] = inv.created_at&.iso8601
              end
              data
            },
            meta: meta
          }
        end

        # GET /api/v1/admin/users/:id
        def show
          render json: { user: ApiSerializers.user(@user).merge(status: @user.status) }
        end

        # POST /api/v1/admin/users/invite
        # Creates an Invitation record, a pending User record, and sends a magic-link email.
        def invite
          inv_params = params.require(:invitation).permit(:email, :role, :organization_id, :org_name, :org_kind, :assigned_office_id, :country_code)
          email = inv_params[:email].to_s.strip.downcase
          role = inv_params[:role] || "owner"

          # Guard: reject if a non-pending user already exists with this email
          existing_user = User.find_by("LOWER(email) = ?", email)
          if existing_user && existing_user.status != "pending"
            return render json: { error: "already_registered", message: "This email is already registered." }, status: :unprocessable_entity
          end

          # Guard: reject if a pending (non-expired) invitation already exists
          existing_invitation = Invitation.pending.where("LOWER(email) = ?", email).first
          if existing_invitation
            return render json: { error: "already_invited", message: "An invitation has already been sent to this email." }, status: :unprocessable_entity
          end

          # Find or create the organization for this user.
          # organization_id → join an existing org (e.g. office role).
          # org_kind + org_name → create a brand-new org (agency/hotel).
          org = if inv_params[:organization_id].present?
                  Organization.find(inv_params[:organization_id])
                else
                  org_attrs = {
                    name: inv_params[:org_name] || "#{email.split('@').first.titleize} Org",
                    kind: inv_params[:org_kind] || "agency",
                    status: "pending"
                  }
                  if inv_params[:country_code].present?
                    org_attrs[:country_code] = inv_params[:country_code]
                    country_record = Country.find_by(code: inv_params[:country_code].upcase)
                    org_attrs[:country] = country_record&.name || inv_params[:country_code]
                  end
                  new_org = Organization.create!(org_attrs)
                  if inv_params[:assigned_office_id].present?
                    new_org.update!(assigned_office_id: inv_params[:assigned_office_id])
                  end
                  new_org
                end

          invitation = Invitation.new(
            email: email,
            role: role,
            organization: org,
            invited_by: current_user
          )
          invitation.save!

          # Also create a pending User so it appears in the admin network list
          temp_password = SecureRandom.hex(16)
          user = User.find_or_create_by!(email: email) do |u|
            u.name = email.split("@").first.titleize
            u.password = temp_password
            u.password_confirmation = temp_password
            u.role = role
            u.organization = org
            u.status = "pending"
          end

          # Auto-approve logic:
          # - Admin invites agency/office → auto-approve (user active, org verified)
          # - Admin invites hotel → stays pending (requires listing review)
          # - Office invites anyone → stays pending (requires admin review)
          inviter_is_admin = current_user.organization.admin?
          if inviter_is_admin && org.kind != "hotel"
            user.update!(status: "active")
            org.update!(status: "verified") if org.status == "pending"
          end

          # Deliver the invitation email. If delivery fails (e.g. Resend domain
          # not verified in dev), log the error but don't crash the request —
          # the invitation record is already created and the magic link works.
          begin
            InvitationMailer.invite(invitation).deliver_now
          rescue StandardError => e
            Rails.logger.warn("[InvitationMailer] Email delivery failed: #{e.message}")
            Rails.logger.info("[InvitationMailer] Magic link for #{email}: #{invitation.magic_link}")
          end

          render json: { invitation: serialize_invitation(invitation) }, status: :created
        end

        # POST /api/v1/admin/users/:id/approve
        def approve
          @user.update!(status: "active")
          @user.organization&.update!(status: "verified") if @user.organization&.status == "pending"

          begin
            ModerationMailer.approved(@user).deliver_now
            ModerationMailer.office_notification(@user, "approved").deliver_now
          rescue StandardError => e
            Rails.logger.warn("[ModerationMailer] Delivery failed: #{e.message}")
          end

          render json: { user: ApiSerializers.user(@user).merge(status: @user.status) }
        end

        # POST /api/v1/admin/users/:id/reject
        def reject
          reason = params[:reason].to_s.strip
          @user.update!(status: "rejected")

          begin
            ModerationMailer.rejected(@user, reason).deliver_now
            ModerationMailer.office_notification(@user, "rejected", reason).deliver_now
          rescue StandardError => e
            Rails.logger.warn("[ModerationMailer] Delivery failed: #{e.message}")
          end

          render json: { user: ApiSerializers.user(@user).merge(status: @user.status) }
        end

        # POST /api/v1/admin/users/:id/send_feedback
        # Sends feedback email to a hotel and marks the submission as
        # "changes requested" until the hotel publishes changes again.
        def send_feedback
          message = params[:message].to_s.strip
          return render json: { error: "Message is required" }, status: :unprocessable_entity if message.blank?

          @user.organization&.update!(review_feedback: message, review_feedback_at: Time.current)

          begin
            ModerationMailer.feedback(@user, message).deliver_now
          rescue StandardError => e
            Rails.logger.warn("[ModerationMailer] Feedback delivery failed: #{e.message}")
          end

          render json: { user: ApiSerializers.user(@user).merge(status: @user.status) }
        end

        # POST /api/v1/admin/users/:id/suspend
        def suspend
          @user.update!(status: "suspended")

          begin
            ModerationMailer.suspended(@user).deliver_now
          rescue StandardError => e
            Rails.logger.warn("[ModerationMailer] Suspend notification failed: #{e.message}")
          end

          render json: { user: ApiSerializers.user(@user).merge(status: @user.status) }
        end

        # POST /api/v1/admin/users/:id/reactivate
        def reactivate
          @user.update!(status: "active")

          begin
            ModerationMailer.reactivated(@user).deliver_now
          rescue StandardError => e
            Rails.logger.warn("[ModerationMailer] Reactivation notification failed: #{e.message}")
          end

          render json: { user: ApiSerializers.user(@user).merge(status: @user.status) }
        end

        # DELETE /api/v1/admin/users/:id
        # Permanently deletes the user, their invitation, and the org if it becomes empty.
        # Wrapped in a transaction so partial deletes never occur.
        def destroy
          ActiveRecord::Base.transaction do
            org = @user.organization

            Invitation.where(email: @user.email).destroy_all
            Invitation.where(invited_by_id: @user.id).update_all(invited_by_id: current_user.id)
            @user.destroy!

            # Clean up orphaned organization (if last user and not the admin org)
            if org && !org.admin? && org.users.reload.count == 0
              purge_organization!(org)
            end
          end

          head :no_content
        end

        private

        def set_user
          @user = User.find(params[:id])
        end

        # Safely destroy an organization and all its dependent data.
        # Rails' dependent: :destroy cascade fails because FK constraints
        # (RESTRICT) block deletion when records in other orgs reference
        # this org's hotels/experiences/retreats/room_types/rooms.
        # This method deletes everything in FK-safe order (leaves first).
        def purge_organization!(org)
          hotel_ids = Hotel.where(organization_id: org.id).pluck(:id)

          if hotel_ids.any?
            experience_ids = Experience.where(hotel_id: hotel_ids).pluck(:id)
            retreat_ids = Retreat.where(hotel_id: hotel_ids).pluck(:id)
            room_type_ids = RoomType.where(hotel_id: hotel_ids).pluck(:id)
            room_ids = Room.where(hotel_id: hotel_ids).pluck(:id)
            retreat_day_ids = retreat_ids.any? ? RetreatDay.where(retreat_id: retreat_ids).pluck(:id) : []

            # Nullify external booking references (from other orgs)
            Booking.where(experience_id: experience_ids).update_all(experience_id: nil) if experience_ids.any?
            Booking.where(retreat_id: retreat_ids).update_all(retreat_id: nil) if retreat_ids.any?
            Booking.where(room_type_id: room_type_ids).update_all(room_type_id: nil) if room_type_ids.any?
            Booking.where(room_id: room_ids).update_all(room_id: nil) if room_ids.any?
            # bookings.hotel_id has on_delete: :nullify at DB level, handled automatically

            # Retreat children (leaves first)
            RetreatActivity.where(retreat_day_id: retreat_day_ids).delete_all if retreat_day_ids.any?
            RetreatDay.where(retreat_id: retreat_ids).delete_all if retreat_ids.any?
            RetreatFacilitator.where(retreat_id: retreat_ids).delete_all if retreat_ids.any?
            RetreatInclusion.where(retreat_id: retreat_ids).delete_all if retreat_ids.any?
            RetreatPricing.where(retreat_id: retreat_ids).delete_all if retreat_ids.any?
            RetreatImage.where(retreat_id: retreat_ids).delete_all if retreat_ids.any?
            Retreat.where(id: retreat_ids).delete_all if retreat_ids.any?

            # Room and inventory children
            InventoryBlock.where(hotel_id: hotel_ids).delete_all
            AvailabilityBlock.where(hotel_id: hotel_ids).delete_all
            RoomImage.where(room_type_id: room_type_ids).delete_all if room_type_ids.any?
            RoomRateTier.where(room_type_id: room_type_ids).delete_all if room_type_ids.any?
            Room.where(id: room_ids).delete_all if room_ids.any?
            RoomType.where(id: room_type_ids).delete_all if room_type_ids.any?

            # Experiences and hotel assets
            Experience.where(hotel_id: hotel_ids).delete_all
            HotelAmenity.where(hotel_id: hotel_ids).delete_all
            HotelImage.where(hotel_id: hotel_ids).delete_all
            Hotel.where(id: hotel_ids).delete_all
          end

          # Reassign retreats created by this org at other hotels
          Retreat.where(created_by_organization_id: org.id).find_each do |retreat|
            retreat.update_columns(created_by_organization_id: retreat.hotel_id ? Hotel.find(retreat.hotel_id).organization_id : nil, created_by_type: "hotel")
          end

          # Org's own data (bookings before clients for FK safety)
          Booking.where(organization_id: org.id).delete_all
          Client.where(organization_id: org.id).delete_all
          InventoryBlock.where(organization_id: org.id).delete_all
          Invitation.where(organization_id: org.id).delete_all
          Subscription.where(organization_id: org.id).delete_all
          StripeConnectAccount.where(organization_id: org.id).delete_all

          # Nullify references from other orgs pointing to this one
          Organization.where(assigned_office_id: org.id).update_all(assigned_office_id: nil)

          org.delete
        end

        def serialize_invitation(inv)
          {
            id: inv.id,
            email: inv.email,
            role: inv.role,
            token: inv.token,
            magic_link: inv.magic_link,
            organization: ApiSerializers.organization(inv.organization),
            expires_at: inv.expires_at,
            invited_by: inv.invited_by&.name
          }
        end
      end
    end
  end
end
