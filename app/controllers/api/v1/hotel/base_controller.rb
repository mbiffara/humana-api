# Base controller for hotel-scoped endpoints. Ensures the authenticated user
# belongs to a hotel-kind organization and provides access to the hotel record.
module Api
  module V1
    module Hotel
      class BaseController < Api::V1::BaseController
        before_action :require_hotel!
        before_action :require_hotel_record!
        after_action :flag_pending_changes

        # Property-content controllers whose writes withdraw a pending
        # submission from admin review until the hotel republishes.
        CONTENT_CONTROLLERS = %w[
          profiles room_types room_images amenities images availability_blocks
        ].freeze

        private

        # When a hotel that already submitted for review (but is not yet
        # approved) edits its property content, mark the submission as having
        # unpublished changes. Cleared by profiles#submit_for_review.
        def flag_pending_changes
          return unless response.successful?
          return if request.get?
          return unless CONTENT_CONTROLLERS.include?(controller_name)
          return if action_name == "submit_for_review"

          org = current_organization
          return unless org&.hotel? && org.onboarding_completed? && org.status == "pending"

          org.update!(pending_changes: true) unless org.pending_changes
        end

        def current_hotel
          @current_hotel ||= current_organization.hotels.first
        end

        def require_hotel!
          render_forbidden("Hotel access required") unless current_organization&.hotel?
        end

        # Hotel orgs have no Hotel record until onboarding creates one; every
        # endpoint except the profile (which builds it) needs one to scope by.
        # Without this guard those endpoints would 500 on a nil current_hotel.
        def require_hotel_record!
          render_forbidden("Hotel profile is not set up yet") if current_hotel.nil?
        end
      end
    end
  end
end
