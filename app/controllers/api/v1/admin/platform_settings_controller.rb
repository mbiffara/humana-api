# Admin endpoint for reading and updating the platform-wide singleton settings.
# Only one row exists in platform_settings — auto-created on first access.
module Api
  module V1
    module Admin
      class PlatformSettingsController < BaseController
        def show
          render json: { platform_setting: ApiSerializers.platform_setting(PlatformSetting.current) }
        end

        def update
          setting = PlatformSetting.current
          if setting.update(setting_params)
            render json: { platform_setting: ApiSerializers.platform_setting(setting) }
          else
            render_unprocessable(setting.errors.full_messages)
          end
        end

        private

        def setting_params
          params.require(:platform_setting).permit(
            :platform_name, :support_email, :default_currency, :default_language,
            :agency_commission_rate, :office_fee_rate, :hotel_net_rate,
            :terms_url, :privacy_url, :logo_url
          )
        end
      end
    end
  end
end
