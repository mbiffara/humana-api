module Api
  module V1
    # An agency's own client book. Scoped to the current organization.
    class ClientsController < BaseController
      before_action :require_agency!
      before_action :set_client, only: %i[show update destroy]

      # GET /api/v1/clients
      def index
        scope = current_organization.clients.order(:name)
        render json: {
          clients: paginate(scope).map { |c| ApiSerializers.client(c) },
          meta: meta_for(scope)
        }
      end

      # GET /api/v1/clients/:id
      def show
        render json: { client: ApiSerializers.client(@client) }
      end

      # POST /api/v1/clients
      def create
        client = current_organization.clients.create!(client_params)
        render json: { client: ApiSerializers.client(client) }, status: :created
      end

      # PATCH/PUT /api/v1/clients/:id
      def update
        @client.update!(client_params)
        render json: { client: ApiSerializers.client(@client) }
      end

      # DELETE /api/v1/clients/:id
      def destroy
        @client.destroy!
        head :no_content
      end

      private

      def set_client
        @client = current_organization.clients.find(params[:id])
      end

      def client_params
        params.require(:client).permit(:name, :email, :phone, :notes)
      end
    end
  end
end
