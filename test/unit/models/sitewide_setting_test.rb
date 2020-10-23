require "test_helper"

class SitewideSettingTest < ActiveSupport::TestCase
 
  test "toggling reshuffle mode republished the ministers index page" do
    payload = PublishingApi::MinistersIndexPresenter.new
    
    stub_publishing_api_publish(payload.content_id, locale: payload.content[:locale])
    
    create(:sitewide_setting, key: :minister_reshuffle_mode, on: true)
  end
end
