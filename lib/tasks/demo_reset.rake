# Resets the database to a clean state for live demos.
# Keeps: admin org, admin user, platform settings, countries, subscription plans.
# Removes everything else.
#
# Usage: rails demo:reset

namespace :demo do
  desc "Reset DB to clean state for live demo (keeps admin + platform config)"
  task reset: :environment do
    puts "Resetting database for live demo..."

    admin_org = Organization.find_by(kind: "admin")
    admin_user_ids = admin_org ? admin_org.users.pluck(:id) : []
    admin_org_id = admin_org&.id

    # Order matters — delete dependents first
    puts "  Removing bookings..."
    Booking.delete_all

    puts "  Removing clients..."
    Client.delete_all

    puts "  Removing experiences..."
    Experience.delete_all

    puts "  Removing retreat data..."
    RetreatActivity.delete_all
    RetreatDay.delete_all
    RetreatFacilitator.delete_all
    RetreatInclusion.delete_all
    RetreatPricing.delete_all
    RetreatImage.delete_all
    Retreat.delete_all

    puts "  Removing hotel data..."
    RoomImage.delete_all
    RoomType.delete_all
    HotelAmenity.delete_all
    HotelImage.delete_all
    Hotel.delete_all

    puts "  Removing subscriptions..."
    Subscription.delete_all

    puts "  Removing stripe accounts..."
    StripeConnectAccount.delete_all

    puts "  Removing invitations..."
    Invitation.delete_all

    puts "  Removing non-admin users..."
    User.where.not(id: admin_user_ids).delete_all

    puts "  Removing non-admin organizations..."
    Organization.where.not(id: admin_org_id).delete_all

    puts ""
    puts "Done. Remaining data:"
    puts "  Organizations: #{Organization.count}"
    puts "  Users:         #{User.count}"
    puts "  Countries:     #{Country.count}"
    puts "  Sub Plans:     #{SubscriptionPlan.count}"
    puts "  Platform:      #{PlatformSetting.count}"
    puts ""
    puts "Ready for live demo. Login: admin@humana.global / humana1234"
  end
end
