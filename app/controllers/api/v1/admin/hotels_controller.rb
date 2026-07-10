module Api
  module V1
    module Admin
      class HotelsController < BaseController
        # GET /api/v1/admin/hotels/:id
        # Returns full hotel profile for admin preview
        def show
          hotel = ::Hotel.find(params[:id])
          org = hotel.organization
          owner = org.users.find_by(role: "owner") || org.users.first

          render json: {
            hotel: ApiSerializers.hotel_full(hotel).merge(
              stars: hotel.stars,
              total_rooms: hotel.total_rooms,
              phone: hotel.phone,
              check_in_time: hotel.check_in_time,
              check_out_time: hotel.check_out_time,
              postal_code: hotel.postal_code,
              logo_url: hotel.logo_url,
              website: hotel.website,
              contact_email: hotel.contact_email,
              onboarding_completed: hotel.onboarding_completed?,
              room_images: hotel.room_types.includes(:room_images).flat_map { |rt|
                rt.room_images.order(:position).map { |ri|
                  { id: ri.id, room_type_id: ri.room_type_id, image_url: ri.image_url, position: ri.position, is_primary: ri.is_primary }
                }
              }
            ),
            organization: ApiSerializers.organization(org, include_onboarding: true),
            owner: owner ? ApiSerializers.user(owner) : nil
          }
        end
      end
    end
  end
end
