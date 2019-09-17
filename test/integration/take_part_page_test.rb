require "test_helper"
require "gds_api/test_helpers/publishing_api_v2"

class TakePartPageTest < ActiveSupport::TestCase
  setup do
    stub_any_publishing_api_call
    @take_part_page = build(:take_part_page)
  end

  test "TakePartPage is published to the Publishing API on save" do
    Sidekiq::Testing.inline! do
      presenter = PublishingApiPresenters.presenter_for(@take_part_page)
      @take_part_page.save!

      expected_json = presenter.content.merge(
        # This is to simulate what the time public timestamp will be after the
        # page has been published
        public_updated_at: Time.zone.now.as_json,
      )

      assert_publishing_api_put_content(@take_part_page.content_id, expected_json)
      assert_publishing_api_publish(@take_part_page.content_id, { update_type: nil,
                                                                  locale: "en" }, 1)
    end
  end

  test "TakePartPage publishes gone route to the Publishing API on destroy" do
    Sidekiq::Testing.inline! do
      Services.asset_manager.stubs(:whitehall_asset).returns("id" => "http://asset-manager/assets/asset-id")
      @take_part_page.save!

      gone_request = stub_publishing_api_unpublish(
        @take_part_page.content_id,
        body: {
          type: "gone",
          locale: "en",
          discard_drafts: true,
        },
      )

      @take_part_page.destroy

      assert_requested gone_request
    end
  end

  test "TakePartPage is published to the Publishing API when updated" do
    Sidekiq::Testing.inline! do
      @take_part_page.save!
      @take_part_page.attributes = { title: "New Title" }
      @take_part_page.save!
      presenter = PublishingApiPresenters.presenter_for(@take_part_page)

      expected_json = presenter.content.merge(
        # This is to simulate what the time public timestamp will be after the
        # page has been published
        public_updated_at: Time.zone.now.as_json,
      )

      assert_publishing_api_put_content(@take_part_page.content_id, expected_json)
      assert_publishing_api_publish(@take_part_page.content_id, { update_type: nil,
                                                                 locale: "en" }, 2)
    end
  end
end
