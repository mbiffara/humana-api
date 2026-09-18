require "rails_helper"

# The onboarding property form (LOG-131..LOG-136) writes the extended hotel
# profile: flexible check-in times, location detail, property type,
# environments, pet policy and group size. `stars` is retired from the API.
RSpec.describe "Hotel profile fields", type: :request do
  let(:hotel_org) { create(:organization, :hotel) }
  let(:owner) { create(:user, :owner, organization: hotel_org) }
  let!(:hotel) { create(:hotel, organization: hotel_org) }

  def patch_profile(attrs)
    patch "/api/v1/hotel/profile",
          params: { hotel: attrs }.to_json,
          headers: auth_headers(owner)
  end

  describe "check-in / check-out times" do
    it "accepts the flexible sentinel" do
      patch_profile(check_in_time: "flexible", check_out_time: "flexible")

      expect(response).to have_http_status(:ok)
      expect(hotel.reload.check_in_time).to eq("flexible")
      expect(hotel.check_out_time).to eq("flexible")
    end

    it "accepts a 24h time" do
      patch_profile(check_in_time: "14:30", check_out_time: "23:59")

      expect(response).to have_http_status(:ok)
      expect(hotel.reload.check_in_time).to eq("14:30")
    end

    it "rejects an impossible time" do
      patch_profile(check_in_time: "25:99")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(hotel.reload.check_in_time).not_to eq("25:99")
    end
  end

  describe "blank optional text" do
    it "stores an empty string as nil instead of failing validation" do
      hotel.update!(check_in_time: "14:00", property_type: "resort",
                    instagram: "@old", airport_transfer: "paid")

      patch_profile(check_in_time: "", property_type: "", instagram: "  ",
                    airport_transfer: "", state_region: "")

      expect(response).to have_http_status(:ok)
      hotel.reload
      expect(hotel.check_in_time).to be_nil
      expect(hotel.property_type).to be_nil
      expect(hotel.instagram).to be_nil
      expect(hotel.airport_transfer).to be_nil
      expect(hotel.state_region).to be_nil
    end

    it "blanks out the location text the same way" do
      patch_profile(city: "", country: "  ", country_code: "")

      expect(response).to have_http_status(:ok)
      hotel.reload
      expect(hotel.city).to be_nil
      expect(hotel.country).to be_nil
      expect(hotel.country_code).to be_nil
    end

    it "clears the free-text label when the property type is blanked out" do
      hotel.update!(property_type: "other", property_type_other: "Glamping dome")

      patch_profile(property_type: "")

      expect(response).to have_http_status(:ok)
      expect(hotel.reload.property_type).to be_nil
      expect(hotel.property_type_other).to be_nil
    end
  end

  describe "property video" do
    %w[
      https://www.youtube.com/watch?v=abc
      https://youtu.be/abc
      https://vimeo.com/76979871
      https://instagram.com/reel/abc
      https://m.youtube.com/watch?v=abc
      https://player.vimeo.com/video/76979871
      https://www.instagram.com/reel/abc
    ].each do |url|
      it "accepts #{url}" do
        patch_profile(video_url: url)

        expect(response).to have_http_status(:ok)
        expect(hotel.reload.video_url).to eq(url)
        expect(response.parsed_body["hotel"]["video_url"]).to eq(url)
      end
    end

    it "rejects a host outside the supported platforms" do
      patch_profile(video_url: "https://tiktok.com/x")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(hotel.reload.video_url).to be_nil
    end

    it "rejects a look-alike domain that merely ends in a supported one" do
      patch_profile(video_url: "https://notyoutube.com/x")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(hotel.reload.video_url).to be_nil
    end

    it "rejects a link that is not http(s)" do
      patch_profile(video_url: "ftp://youtube.com/watch?v=abc")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(hotel.reload.video_url).to be_nil
    end

    it "stores an empty string as nil" do
      hotel.update!(video_url: "https://vimeo.com/76979871")

      patch_profile(video_url: "")

      expect(response).to have_http_status(:ok)
      expect(hotel.reload.video_url).to be_nil
    end

    it "is serialized on the hotel profile" do
      hotel.update!(video_url: "https://youtu.be/abc")

      get "/api/v1/hotel/profile", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["hotel"]["video_url"]).to eq("https://youtu.be/abc")
    end
  end

  describe "retired stars field" do
    it "ignores stars in the payload instead of failing" do
      patch_profile(stars: 5, name: "Still Fine")

      expect(response).to have_http_status(:ok)
      expect(hotel.reload.name).to eq("Still Fine")
      expect(hotel.stars).to be_nil
    end

    it "is no longer serialized on the hotel profile" do
      get "/api/v1/hotel/profile", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["hotel"]).not_to have_key("stars")
    end
  end

  describe "location detail" do
    it "persists and serializes the whole location block" do
      patch_profile(
        state_region: "Islas Baleares",
        instagram: "@shantiwellness",
        nearest_airport: "Ibiza (IBZ)",
        airport_distance_km: 18.5,
        airport_time_min: 25,
        airport_transfer: "included",
        airport_transfer_notes: "Private transfer included.",
        distance_to_center_km: 12.0,
        latitude: 38.8806,
        longitude: 1.4076
      )

      expect(response).to have_http_status(:ok)
      body = response.parsed_body["hotel"]
      expect(body["state_region"]).to eq("Islas Baleares")
      expect(body["instagram"]).to eq("@shantiwellness")
      expect(body["nearest_airport"]).to eq("Ibiza (IBZ)")
      expect(body["airport_distance_km"]).to eq(18.5)
      expect(body["airport_time_min"]).to eq(25)
      expect(body["airport_transfer"]).to eq("included")
      expect(body["airport_transfer_notes"]).to eq("Private transfer included.")
      expect(body["distance_to_center_km"]).to eq(12.0)

      hotel.reload
      expect(hotel.airport_distance_km).to eq(18.5)
      expect(hotel.airport_time_min).to eq(25)
    end

    it "rejects an unknown transfer option" do
      patch_profile(airport_transfer: "taxi")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(hotel.reload.airport_transfer).to be_nil
    end

    it "rejects a negative airport distance" do
      patch_profile(airport_distance_km: -1)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects an out-of-range latitude" do
      patch_profile(latitude: 95)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects an out-of-range longitude" do
      patch_profile(longitude: -200)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "property type" do
    it "rejects an unknown property type" do
      patch_profile(property_type: "castle")

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "requires the free-text label when the type is other" do
      patch_profile(property_type: "other")

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "accepts other together with its label" do
      patch_profile(property_type: "other", property_type_other: "Glamping dome")

      expect(response).to have_http_status(:ok)
      expect(hotel.reload.property_type_other).to eq("Glamping dome")
    end

    it "drops the free-text label for a known type" do
      patch_profile(property_type: "hotel", property_type_other: "Glamping dome")

      expect(response).to have_http_status(:ok)
      expect(hotel.reload.property_type).to eq("hotel")
      expect(hotel.property_type_other).to be_nil
    end
  end

  describe "environments" do
    it "persists a multi-select" do
      patch_profile(environments: %w[beach island])

      expect(response).to have_http_status(:ok)
      expect(hotel.reload.environments).to eq(%w[beach island])
      expect(response.parsed_body["hotel"]["environments"]).to eq(%w[beach island])
    end

    it "rejects an unknown environment" do
      patch_profile(environments: %w[desert])

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "deduplicates repeated values" do
      patch_profile(environments: %w[beach beach])

      expect(response).to have_http_status(:ok)
      expect(hotel.reload.environments).to eq(%w[beach])
    end

    # Checkbox groups post a blank entry when nothing is ticked.
    it "drops blank entries posted by an empty checkbox group" do
      hotel.update!(environments: %w[beach])

      patch_profile(environments: [""])

      expect(response).to have_http_status(:ok)
      expect(hotel.reload.environments).to eq([])
    end

    it "clears the selection with an empty array" do
      hotel.update!(environments: %w[beach])

      patch_profile(environments: [])

      expect(response).to have_http_status(:ok)
      expect(hotel.reload.environments).to eq([])
    end
  end

  describe "pet policy" do
    let(:full_policy) do
      {
        pet_friendly: true,
        pet_dogs: true,
        pet_cats: true,
        pet_size_restriction: true,
        pet_size_restriction_notes: "Up to 15 kg.",
        pet_extra_cost: true,
        pet_extra_cost_notes: "25 EUR per night.",
        pet_common_areas: true,
        pet_specific_rooms: true
      }
    end

    it "persists the whole policy when pet friendly" do
      patch_profile(full_policy)

      expect(response).to have_http_status(:ok)
      hotel.reload
      expect(hotel.pet_friendly).to be(true)
      expect(hotel.pet_dogs).to be(true)
      expect(hotel.pet_size_restriction_notes).to eq("Up to 15 kg.")
      expect(hotel.pet_extra_cost_notes).to eq("25 EUR per night.")
      expect(hotel.pet_common_areas).to be(true)
      expect(hotel.pet_specific_rooms).to be(true)
    end

    it "wipes the detail when the hotel stops being pet friendly" do
      patch_profile(full_policy)
      expect(response).to have_http_status(:ok)

      patch_profile(pet_friendly: false)

      expect(response).to have_http_status(:ok)
      hotel.reload
      expect(hotel.pet_friendly).to be(false)
      expect(hotel.pet_dogs).to be_nil
      expect(hotel.pet_cats).to be_nil
      expect(hotel.pet_size_restriction).to be_nil
      expect(hotel.pet_size_restriction_notes).to be_nil
      expect(hotel.pet_extra_cost).to be_nil
      expect(hotel.pet_extra_cost_notes).to be_nil
      expect(hotel.pet_common_areas).to be_nil
      expect(hotel.pet_specific_rooms).to be_nil
    end

    it "drops a note whose own flag is off" do
      patch_profile(
        pet_friendly: true,
        pet_size_restriction: false,
        pet_size_restriction_notes: "Up to 15 kg.",
        pet_extra_cost: true,
        pet_extra_cost_notes: "25 EUR per night."
      )

      expect(response).to have_http_status(:ok)
      hotel.reload
      expect(hotel.pet_size_restriction_notes).to be_nil
      expect(hotel.pet_extra_cost_notes).to eq("25 EUR per night.")
    end
  end

  describe "group size" do
    it "persists a valid range" do
      patch_profile(group_min_guests: 10, group_max_guests: 40)

      expect(response).to have_http_status(:ok)
      hotel.reload
      expect(hotel.group_min_guests).to eq(10)
      expect(hotel.group_max_guests).to eq(40)
    end

    it "rejects a maximum below the minimum" do
      patch_profile(group_min_guests: 10, group_max_guests: 5)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["details"].join).to match(/minimum group size/i)
    end

    it "rejects a non-positive minimum" do
      patch_profile(group_min_guests: 0)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "accepts a minimum on its own" do
      patch_profile(group_min_guests: 8)

      expect(response).to have_http_status(:ok)
      expect(hotel.reload.group_min_guests).to eq(8)
    end
  end

  describe "property highlight" do
    it "accepts 500 characters" do
      patch_profile(highlight: "a" * 500)

      expect(response).to have_http_status(:ok)
      expect(hotel.reload.highlight.length).to eq(500)
      expect(response.parsed_body["hotel"]["highlight"].length).to eq(500)
    end

    it "rejects 501 characters" do
      patch_profile(highlight: "a" * 501)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(hotel.reload.highlight).to be_nil
    end

    it "stores an empty string as nil" do
      hotel.update!(highlight: "Something special")

      patch_profile(highlight: "")

      expect(response).to have_http_status(:ok)
      expect(hotel.reload.highlight).to be_nil
    end

    # The pitch is what sells the property, so it is public. The verification
    # block behind it is not.
    it "is public, while the verification block is not" do
      hotel.update!(highlight: "Clifftop yoga over the Mediterranean.")
      hotel_org.update!(
        legal_name: "Shanti Wellness S.L.",
        tax_id: "B12345678",
        ownership_document_url: "https://cdn.humana.global/documents/deed.pdf"
      )

      get "/api/v1/public/hotels/#{hotel.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body["hotel"]
      expect(body["highlight"]).to eq("Clifftop yoga over the Mediterranean.")
      expect(body).not_to have_key("legal_name")
      expect(body).not_to have_key("tax_id")
      expect(body).not_to have_key("ownership_document_url")
      expect(body).not_to have_key("social_links")
      expect(response.parsed_body).not_to have_key("organization")
    end
  end

  describe "verification block" do
    def patch_organization(attrs)
      patch "/api/v1/hotel/profile",
            params: { organization: attrs }.to_json,
            headers: auth_headers(owner)
    end

    let(:verification) do
      {
        legal_name: "Shanti Wellness S.L.",
        business_name: "Shanti Retreat Ibiza",
        tax_id: "B12345678",
        primary_contact: "Marta Ferrer",
        primary_contact_role: "Directora General",
        commercial_registration: "RM Ibiza, tomo 1234, folio 56",
        phone: "+34 971 123 456",
        contact_email: "legal@shantiretreat.com",
        website: "https://shantiretreat.com",
        social_links: { instagram: "https://instagram.com/shanti", facebook: "https://facebook.com/shanti" },
        ownership_document_url: "https://cdn.humana.global/documents/deed.pdf",
        authorization_declared: true
      }
    end

    it "persists the whole block sent without any hotel data" do
      patch_organization(verification)

      expect(response).to have_http_status(:ok)
      org = hotel_org.reload
      expect(org.legal_name).to eq("Shanti Wellness S.L.")
      expect(org.business_name).to eq("Shanti Retreat Ibiza")
      expect(org.tax_id).to eq("B12345678")
      expect(org.primary_contact_role).to eq("Directora General")
      expect(org.commercial_registration).to eq("RM Ibiza, tomo 1234, folio 56")
      expect(org.social_links).to eq(
        "instagram" => "https://instagram.com/shanti",
        "facebook" => "https://facebook.com/shanti"
      )
      expect(org.ownership_document_url).to eq("https://cdn.humana.global/documents/deed.pdf")
      expect(org.authorization_declared_at).to be_present
    end

    it "serializes the block back on the same response" do
      patch_organization(verification)

      body = response.parsed_body["organization"]
      expect(body["legal_name"]).to eq("Shanti Wellness S.L.")
      expect(body["business_name"]).to eq("Shanti Retreat Ibiza")
      expect(body["primary_contact_role"]).to eq("Directora General")
      expect(body["commercial_registration"]).to eq("RM Ibiza, tomo 1234, folio 56")
      expect(body["social_links"]).to eq(
        "instagram" => "https://instagram.com/shanti",
        "facebook" => "https://facebook.com/shanti"
      )
      expect(body["ownership_document_url"]).to eq("https://cdn.humana.global/documents/deed.pdf")
      expect(body["authorization_declared_at"]).to be_present
    end

    it "keeps the original timestamp when the declaration is re-sent" do
      patch_organization(authorization_declared: true)
      first = hotel_org.reload.authorization_declared_at

      patch_organization(authorization_declared: "true")

      expect(hotel_org.reload.authorization_declared_at).to eq(first)
    end

    it "withdraws the declaration when it is unticked" do
      patch_organization(authorization_declared: true)
      expect(hotel_org.reload.authorization_declared_at).to be_present

      patch_organization(authorization_declared: false)

      expect(response).to have_http_status(:ok)
      expect(hotel_org.reload.authorization_declared_at).to be_nil
    end

    it "leaves the declaration alone when the key is absent" do
      hotel_org.update!(authorization_declared_at: 2.days.ago)
      before = hotel_org.reload.authorization_declared_at

      patch_organization(legal_name: "Shanti Wellness S.L.")

      expect(hotel_org.reload.authorization_declared_at).to eq(before)
    end

    it "clears a field sent back empty" do
      hotel_org.update!(legal_name: "Old S.L.")

      patch_organization(legal_name: "")

      expect(response).to have_http_status(:ok)
      expect(hotel_org.reload.legal_name).to be_nil
    end

    it "rejects a social network it does not know" do
      patch_organization(social_links: { myspace: "https://myspace.com/shanti" })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["details"].join).to match(/unknown keys/i)
      expect(hotel_org.reload.social_links).to eq({})
    end

    it "rejects a website without a scheme" do
      patch_organization(website: "shantiretreat.com")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(hotel_org.reload.website).to be_nil
    end

    # Organizations onboarded before the format rule existed keep a bare
    # domain. That stops them from changing the website, not from saving.
    context "with a bare domain stored before the rule existed" do
      before { hotel_org.update_column(:website, "old-domain.com") }

      it "still accepts an edit to another field" do
        patch_organization(legal_name: "Shanti Wellness S.L.")

        expect(response).to have_http_status(:ok)
        expect(hotel_org.reload.legal_name).to eq("Shanti Wellness S.L.")
        expect(hotel_org.website).to eq("old-domain.com")
      end

      it "still accepts an edit that only changes the hotel name" do
        patch_profile(name: "Shanti Retreat Renamed")

        expect(response).to have_http_status(:ok)
        expect(hotel_org.reload.name).to eq("Shanti Retreat Renamed")
      end

      it "still rejects moving the website to another scheme-less domain" do
        patch_organization(website: "example.com")

        expect(response).to have_http_status(:unprocessable_entity)
        expect(hotel_org.reload.website).to eq("old-domain.com")
      end

      it "accepts a proper link as the replacement" do
        patch_organization(website: "https://example.com")

        expect(response).to have_http_status(:ok)
        expect(hotel_org.reload.website).to eq("https://example.com")
      end
    end

    it "drops a social link sent empty" do
      patch_organization(social_links: { instagram: "https://instagram.com/shanti", facebook: "" })

      expect(response).to have_http_status(:ok)
      expect(hotel_org.reload.social_links).to eq("instagram" => "https://instagram.com/shanti")
    end

    it "is returned by GET profile together with the hotel highlight" do
      hotel.update!(highlight: "Clifftop yoga over the Mediterranean.")
      patch_organization(verification)

      get "/api/v1/hotel/profile", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["hotel"]["highlight"]).to eq("Clifftop yoga over the Mediterranean.")
      org = response.parsed_body["organization"]
      expect(org["business_name"]).to eq("Shanti Retreat Ibiza")
      expect(org["primary_contact_role"]).to eq("Directora General")
      expect(org["commercial_registration"]).to eq("RM Ibiza, tomo 1234, folio 56")
      expect(org["social_links"]).to have_key("instagram")
      expect(org["ownership_document_url"]).to be_present
      expect(org["authorization_declared_at"]).to be_present
    end

    it "does not touch the bank block when only verification data is sent" do
      patch_organization(legal_name: "Shanti Wellness S.L.")

      expect(hotel_org.reload.bank_status).to eq("pending")
    end
  end

  describe "verification sent before the hotel exists" do
    let(:fresh_org) { create(:organization, :hotel) }
    let(:fresh_owner) { create(:user, :owner, organization: fresh_org) }

    it "is rejected because there is no property to attach it to" do
      patch "/api/v1/hotel/profile",
            params: { organization: { legal_name: "Shanti Wellness S.L." } }.to_json,
            headers: auth_headers(fresh_owner)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["details"]).to eq(["Hotel data is required"])
      expect(fresh_org.reload.legal_name).to be_nil
    end

    it "is accepted alongside the hotel name that creates the property" do
      patch "/api/v1/hotel/profile",
            params: { hotel: { name: "Shanti Retreat" },
                      organization: { legal_name: "Shanti Wellness S.L." } }.to_json,
            headers: auth_headers(fresh_owner)

      expect(response).to have_http_status(:ok)
      expect(fresh_org.reload.legal_name).to eq("Shanti Wellness S.L.")
      expect(fresh_org.hotels.first.name).to eq("Shanti Retreat")
    end
  end

  describe "admin preview" do
    let(:admin) { create(:user, :admin) }

    before do
      hotel.update!(
        property_type: "eco_lodge",
        environments: %w[jungle beach],
        state_region: "Quintana Roo",
        nearest_airport: "Cancun (CUN)",
        pet_friendly: true,
        pet_dogs: true,
        group_min_guests: 20,
        group_max_guests: 120
      )
    end

    it "exposes the new profile fields and no longer exposes stars" do
      get "/api/v1/admin/hotels/#{hotel.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body["hotel"]
      expect(body).not_to have_key("stars")
      expect(body["property_type"]).to eq("eco_lodge")
      expect(body["environments"]).to eq(%w[jungle beach])
      expect(body["state_region"]).to eq("Quintana Roo")
      expect(body["nearest_airport"]).to eq("Cancun (CUN)")
      expect(body["pet_friendly"]).to be(true)
      expect(body["pet_dogs"]).to be(true)
      expect(body["group_min_guests"]).to eq(20)
      expect(body["group_max_guests"]).to eq(120)
    end

    it "carries the verification block on the organization" do
      hotel_org.update!(
        legal_name: "Shanti Wellness S.L.",
        business_name: "Shanti Retreat Ibiza",
        tax_id: "B12345678",
        primary_contact: "Marta Ferrer",
        primary_contact_role: "Directora General",
        commercial_registration: "RM Ibiza, tomo 1234, folio 56",
        website: "https://shantiretreat.com",
        social_links: { "instagram" => "https://instagram.com/shanti" },
        ownership_document_url: "https://cdn.humana.global/documents/deed.pdf",
        authorization_declared_at: Time.current
      )
      hotel.update!(highlight: "Clifftop yoga over the Mediterranean.")

      get "/api/v1/admin/hotels/#{hotel.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["hotel"]["highlight"]).to eq("Clifftop yoga over the Mediterranean.")
      org = response.parsed_body["organization"]
      expect(org["legal_name"]).to eq("Shanti Wellness S.L.")
      expect(org["business_name"]).to eq("Shanti Retreat Ibiza")
      expect(org["tax_id"]).to eq("B12345678")
      expect(org["primary_contact_role"]).to eq("Directora General")
      expect(org["commercial_registration"]).to eq("RM Ibiza, tomo 1234, folio 56")
      expect(org["social_links"]).to eq("instagram" => "https://instagram.com/shanti")
      expect(org["ownership_document_url"]).to eq("https://cdn.humana.global/documents/deed.pdf")
      expect(org["authorization_declared_at"]).to be_present
    end

    it "still carries the fields the preview used to merge in by hand" do
      hotel.update!(total_rooms: 24, phone: "+34 971 123 456", postal_code: "07830")

      get "/api/v1/admin/hotels/#{hotel.id}", headers: auth_headers(admin)

      body = response.parsed_body["hotel"]
      expect(body["total_rooms"]).to eq(24)
      expect(body["phone"]).to eq("+34 971 123 456")
      expect(body["postal_code"]).to eq("07830")
      expect(body).to have_key("check_in_time")
      expect(body).to have_key("onboarding_completed")
      expect(body).to have_key("room_images")
    end
  end
end
