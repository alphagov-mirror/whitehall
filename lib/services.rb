require "gds_api/publishing_api_v2"
require "gds_api/asset_manager"
require "gds_api/email_alert_api"

module Services
  def self.publishing_api
    @publishing_api ||= publishing_api_client_with_timeout(20)
  end

  def self.publishing_api_with_low_timeout
    @publishing_api_with_low_timeout ||= publishing_api_client_with_timeout(1)
  end

  def self.asset_manager
    @asset_manager ||= GdsApi::AssetManager.new(
      Plek.find("asset-manager"),
      bearer_token: ENV.fetch("ASSET_MANAGER_BEARER_TOKEN", "12345678"),
    )
  end

  def self.email_alert_api
    @email_alert_api ||= GdsApi::EmailAlertApi.new(
      Plek.find("email-alert-api"),
      bearer_token: ENV.fetch("EMAIL_ALERT_API_BEARER_TOKEN", "gazorpazorp"),
    )
  end

  def self.publishing_api_client_with_timeout(timeout)
    GdsApi::PublishingApiV2.new(
      Plek.find("publishing-api"),
      bearer_token: ENV.fetch("PUBLISHING_API_BEARER_TOKEN", "example"),
      timeout: timeout,
    )
  end
end
