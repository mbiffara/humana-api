# Admin CRUD for organizations.
# Lists all non-admin organizations with filters for kind, status, country, and search.
module Api
  module V1
    module Admin
      class OrganizationsController < BaseController
        before_action :set_organization, only: %i[show update destroy]

        # GET /api/v1/admin/organizations
        # Filters: kind, status, country, q (name/city/country search)
        def index
          scope = Organization.where.not(kind: "admin")
          scope = scope.where(kind: params[:kind]) if params[:kind].present?
          scope = scope.where(status: params[:status]) if params[:status].present?
          scope = scope.where("country_code = ?", params[:country].upcase) if params[:country].present?
          scope = scope.where("name ILIKE :q OR city ILIKE :q OR country ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?

          scope = scope.order(:name)
          meta = meta_for(scope)

          render json: {
            organizations: paginate(scope).map { |o| serialize_org(o) },
            meta: meta
          }
        end

        # GET /api/v1/admin/organizations/:id
        def show
          render json: { organization: serialize_org(@organization) }
        end

        # POST /api/v1/admin/organizations
        def create
          org = Organization.new(organization_params)
          org.save!
          render json: { organization: serialize_org(org) }, status: :created
        end

        # PATCH/PUT /api/v1/admin/organizations/:id
        def update
          @organization.update!(organization_params)
          render json: { organization: serialize_org(@organization) }
        end

        # DELETE /api/v1/admin/organizations/:id
        def destroy
          @organization.destroy!
          head :no_content
        end

        private

        def set_organization
          @organization = Organization.find(params[:id])
        end

        def organization_params
          params.require(:organization).permit(
            :name, :kind, :status, :city, :country, :country_code,
            :contact_email, :website, :sponsored
          )
        end

        # Extends the base serializer with user_count for admin views.
        def serialize_org(org)
          ApiSerializers.organization(org).merge(
            contact_email: org.contact_email,
            user_count: org.users.count
          )
        end
      end
    end
  end
end
