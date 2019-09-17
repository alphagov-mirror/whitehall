require "test_helper"

class WorldLocationNewsPageWorkerTest < ActiveSupport::TestCase
  test "sends to the publishing api" do
    world_location = FactoryBot.create(
      :world_location,
      name: "France",
      news_page_content_id: "id-123",
    )
    presenter = PublishingApi::WorldLocationNewsPagePresenter.new(world_location)

    Services.publishing_api.expects(:put_content).with("id-123", presenter.content)
    Services.publishing_api.expects(:publish).with("id-123", nil, locale: :en)

    WorldLocationNewsPageWorker.new.perform(world_location.id)
  end

  test "sends to rummager" do
    world_location = FactoryBot.create(
      :world_location,
      name: "France",
      news_page_content_id: "id-123",
    )
    presenter = PublishingApi::WorldLocationNewsPagePresenter.new(world_location)

    Whitehall::FakeRummageableIndex.any_instance.expects(:add)
      .with(presenter.content_for_rummager("id-123"))

    WorldLocationNewsPageWorker.new.perform(world_location.id)
  end

  test "sends translations to the publishing api under the same content_id" do
    world_location = FactoryBot.create(
      :world_location,
      name: "France",
      news_page_content_id: "id-123",
      translated_into: [:fr],
    )

    I18n.with_locale(:en) do
      @english = PublishingApi::WorldLocationNewsPagePresenter.new(world_location).content
    end

    I18n.with_locale(:fr) do
      @french = PublishingApi::WorldLocationNewsPagePresenter.new(world_location).content
    end

    Services.publishing_api.expects(:put_content).with("id-123", @english)
    Services.publishing_api.expects(:publish).with("id-123", nil, locale: :en)

    Services.publishing_api.expects(:put_content).with("id-123", @french)
    Services.publishing_api.expects(:publish).with("id-123", nil, locale: :fr)

    WorldLocationNewsPageWorker.new.perform(world_location.id)
  end
end
