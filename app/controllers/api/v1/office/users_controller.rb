# Office user management — list regional users and invite new hotel/agency users.
# Unlike admin, office cannot approve/reject/suspend/reactivate. All invited
# users stay pending until the admin approves them.
module Api
  module V1
    module Office
      class UsersController < BaseController
        # GET /api/v1/office/users
        def index
          scope = User.where(organization_id: regional_organizations.select(:id))
          scope = scope.includes(:organization)
          scope = scope.where("users.name ILIKE :q OR users.email ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?
          scope = scope.where(organizations: { kind: params[:kind] }) if params[:kind].present?
          scope = scope.order("users.created_at DESC")

          meta = meta_for(scope)
          paginated = paginate(scope)

          render json: {
            users: paginated.map { |u| ApiSerializers.user(u).merge(status: u.status) },
            meta: meta
          }
        end

        # GET /api/v1/office/users/:id
        def show
          user = User.where(organization_id: regional_organizations.select(:id)).find(params[:id])
          render json: { user: ApiSerializers.user(user).merge(status: user.status) }
        end

        # POST /api/v1/office/users/invite
        # Creates a new hotel or agency user in the office's region.
        # The user+org remain pending until the platform admin approves.
        def invite
          inv_params = params.require(:invitation).permit(:email, :org_name, :org_kind, :country_code)
          email = inv_params[:email].to_s.strip.downcase
          org_kind = inv_params[:org_kind].to_s

          # Only hotel and agency can be created by office
          unless %w[hotel agency].include?(org_kind)
            return render json: { error: "Office can only create hotel or agency users." }, status: :unprocessable_entity
          end

          return render json: { error: "Email is required" }, status: :unprocessable_entity if email.blank?

          existing_user = User.find_by("LOWER(email) = ?", email)
          if existing_user && existing_user.status != "pending"
            return render json: { error: "already_registered", message: "This email is already registered." }, status: :unprocessable_entity
          end

          existing_inv = Invitation.pending.where("LOWER(email) = ?", email).first
          if existing_inv
            return render json: { error: "already_invited", message: "An invitation has already been sent." }, status: :unprocessable_entity
          end

          # Create organization
          country_code = (inv_params[:country_code].presence || current_organization.country_code).to_s.upcase
          country_record = Country.find_by(code: country_code)

          org = Organization.create!(
            name: inv_params[:org_name] || "#{email.split('@').first.titleize} Org",
            kind: org_kind,
            status: "pending",
            country_code: country_code,
            country: country_record&.name || country_code,
            assigned_office_id: current_organization.id
          )

          invitation = Invitation.create!(
            email: email,
            role: "owner",
            organization: org,
            invited_by: current_user
          )

          # Create pending user
          temp_password = SecureRandom.hex(16)
          User.find_or_create_by!(email: email) do |u|
            u.name = email.split("@").first.titleize
            u.password = temp_password
            u.password_confirmation = temp_password
            u.role = "owner"
            u.organization = org
            u.status = "pending"
          end

          begin
            InvitationMailer.invite(invitation).deliver_now
          rescue StandardError => e
            Rails.logger.warn("[InvitationMailer] Email delivery failed: #{e.message}")
          end

          render json: {
            invitation: {
              id: invitation.id,
              email: invitation.email,
              role: invitation.role,
              organization: ApiSerializers.organization(org),
              expires_at: invitation.expires_at,
              invited_by: current_user.name
            }
          }, status: :created
        end
      end
    end
  end
end
