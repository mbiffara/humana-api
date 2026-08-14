# Resets the database to a clean state for live demos.
# Keeps: admin org, admin user, platform settings, countries, subscription plans.
# Removes everything else in FK-safe order.
#
# Usage: rails demo:reset

namespace :demo do
  desc "Reset DB to clean state for live demo (keeps admin + platform config)"
  task reset: :environment do
    puts "Resetting database for live demo..."

    admin_org = Organization.find_by(kind: "admin")
    admin_user_ids = admin_org ? admin_org.users.pluck(:id) : []
    admin_org_id = admin_org&.id

    ActiveRecord::Base.transaction do
      # --- Bookings & clients (leaf records that reference everything) ---
      puts "  Removing bookings..."
      Booking.delete_all

      puts "  Removing clients..."
      Client.delete_all

      # --- Inventory & availability blocks (reference hotel + room_type) ---
      puts "  Removing inventory blocks..."
      InventoryBlock.delete_all

      puts "  Removing availability blocks..."
      AvailabilityBlock.delete_all

      # --- Experiences ---
      puts "  Removing experiences..."
      Experience.delete_all

      # --- Retreat data (leaves first) ---
      puts "  Removing retreat data..."
      RetreatActivity.delete_all
      RetreatDay.delete_all
      RetreatFacilitator.delete_all
      RetreatInclusion.delete_all
      RetreatPricing.delete_all
      RetreatImage.delete_all
      Retreat.delete_all

      # --- Room data (images & rate tiers before rooms, rooms before types) ---
      puts "  Removing room data..."
      RoomImage.delete_all
      RoomRateTier.delete_all
      Room.delete_all
      RoomType.delete_all

      # --- Hotel assets ---
      puts "  Removing hotel data..."
      HotelAmenity.delete_all
      HotelImage.delete_all
      Hotel.delete_all

      # --- Subscriptions & Stripe ---
      puts "  Removing subscriptions..."
      Subscription.delete_all
      StripeConnectAccount.delete_all

      # --- Invitations (references users via invited_by_id) ---
      puts "  Removing invitations..."
      Invitation.delete_all

      # --- Non-admin users ---
      puts "  Removing non-admin users..."
      User.where.not(id: admin_user_ids).delete_all

      # --- Non-admin organizations (clear self-referencing FK first) ---
      puts "  Removing non-admin organizations..."
      Organization.where.not(id: admin_org_id).update_all(assigned_office_id: nil)
      Organization.where.not(id: admin_org_id).delete_all
    end

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
