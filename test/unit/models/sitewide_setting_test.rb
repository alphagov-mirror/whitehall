require "test_helper"

class SitewideSettingTest < ActiveSupport::TestCase
 
  test "toggling reshuffle mode republished the ministers index page" do
    payload = PublishingApi::MinistersIndexPresenter.new
    
    Services.publishing_api.expects(:publish).with(payload.content_id, nil, locale: "en").once

    create(:sitewide_setting, key: :minister_reshuffle_mode, on: true)
  end
end
