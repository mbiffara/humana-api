module Api
  module V1
    module Hotel
      class ProfilesController < BaseController
        # The profile endpoint is the one place a hotel org without a Hotel
        # record may go — updating it builds the record during onboarding.
        skip_before_action :require_hotel_record!

        # GET /api/v1/hotel/profile
        def show
          render json: {
            hotel: current_hotel ? ApiSerializers.hotel_full(current_hotel) : nil,
            organization: ApiSerializers.organization(current_organization, include_onboarding: true)
          }
        end

        # PATCH /api/v1/hotel/profile
        def update
          # The verification block lives on the organization, so a request may
          # legitimately carry no hotel key at all — but only once the hotel
          # record exists. Without one there is nothing to build it from.
          if hotel_params.empty? && current_hotel.nil?
            return render_unprocessable(["Hotel data is required"])
          end

          # Bank details and verification block travel nested under the
          # organization key. The one check the permit cannot make comes first,
          # while nothing has been written yet.
          org_params = params[:organization].present? ? params.require(:organization) : nil
          if org_params && !social_links_shape_ok?(org_params)
            return render_unprocessable(["social_links must be an object"])
          end

          hotel = current_hotel || current_organization.hotels.build

          # One form, one save. A property that fails on the verification block
          # must not be left with half of its profile rewritten — and a 422
          # leaves the submission untouched, so `flag_pending_changes` stays
          # honest about what is actually published.
          ActiveRecord::Base.transaction do
            hotel.assign_attributes(hotel_params)
            hotel.save!
            # Keep organization name in sync with hotel name
            current_organization.update!(name: hotel.name) if hotel.name.present?
            current_user.update!(name: params[:user_name]) if params[:user_name].present?
            current_user.update!(phone: params[:user_phone]) if params[:user_phone].present?

            if org_params
              bank_attrs = org_params.permit(
                :bank_account_holder, :bank_iban, :bank_swift,
                :bank_currency, :bank_country
              )
              if bank_attrs.values.any?(&:present?)
                bank_attrs[:bank_status] = "configured"
                current_organization.update!(bank_attrs)
              end

              # An empty value is still an answer — it clears the field — so
              # the presence of the key, not of a value, decides whether we
              # write.
              verification = verification_attrs(org_params)
              current_organization.update!(verification) if verification.keys.any?
            end
          end

          render json: {
            hotel: ApiSerializers.hotel_full(hotel),
            organization: ApiSerializers.organization(current_organization.reload, include_onboarding: true)
          }
        end

        # POST /api/v1/hotel/profile/submit_for_review
        def submit_for_review
          current_organization.update!(
            onboarding_completed_at: Time.current,
            pending_changes: false,
            review_feedback: nil,
            review_feedback_at: nil
          )
          render json: { user: ApiSerializers.user(current_user.reload) }
        end

        private

        # The verification fields the property registers for review: who owns
        # or represents it legally, who answers for it, and the document and
        # declaration that back the claim.
        #
        # `social_links` is permitted as an open hash on purpose. Naming the
        # known networks here would filter the rest out silently and answer
        # 200, so the property would never learn about the typo; with the hash
        # open, Organization#social_links_must_be_known answers 422 instead.
        def verification_attrs(org_params)
          attrs = org_params.permit(
            :legal_name, :business_name, :tax_id,
            :primary_contact, :primary_contact_role, :commercial_registration,
            :phone, :contact_email, :website,
            :ownership_document_url, :authorization_declared,
            social_links: {}
          )

          declared = attrs.delete(:authorization_declared)
          unless declared.nil?
            attrs[:authorization_declared_at] =
              if ActiveModel::Type::Boolean.new.cast(declared)
                current_organization.authorization_declared_at || Time.current
              end
          end

          attrs
        end

        # `permit(social_links: {})` keeps a hash and drops anything else, so a
        # string or a list would vanish without a word. Catch that shape here,
        # where we can still say what was wrong.
        def social_links_shape_ok?(org_params)
          value = org_params[:social_links]

          value.nil? || value.is_a?(ActionController::Parameters) || value.is_a?(Hash)
        end

        def hotel_params
          @hotel_params ||= begin
            raw = params[:hotel]
            raw = ActionController::Parameters.new unless raw.is_a?(ActionController::Parameters)
            raw.permit(
              :name, :city, :country, :country_code, :latitude, :longitude,
              :description, :address, :certified, :wellness_standard,
              :phone, :check_in_time, :check_out_time, :total_rooms,
              :website, :contact_email, :postal_code, :logo_url, :video_url,
              :highlight,
              # Location detail
              :state_region, :instagram, :nearest_airport, :airport_distance_km,
              :airport_time_min, :airport_transfer, :airport_transfer_notes,
              :distance_to_center_km,
              # Property type and environments
              :property_type, :property_type_other, { environments: [] },
              # Pet policy
              :pet_friendly, :pet_dogs, :pet_cats, :pet_size_restriction,
              :pet_size_restriction_notes, :pet_extra_cost, :pet_extra_cost_notes,
              :pet_common_areas, :pet_specific_rooms,
              # Group size
              :group_min_guests, :group_max_guests
            )
          end
        end
      end
    end
  end
end
