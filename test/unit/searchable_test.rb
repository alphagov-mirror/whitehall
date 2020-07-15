require "test_helper"

class SearchableTest < ActiveSupport::TestCase
  # re-using an existing table to make these tests much clearer
  # as all the searchable definition is in one place (and it doesn't
  # lend itself to redefinition)
  class SearchableTestTopic < ApplicationRecord
    self.table_name = "classifications"

    include Searchable
    searchable link: :name, only: :publicly_visible

    scope :publicly_visible, -> { where(state: %w[published withdrawn]) }
  end

  def setup
    RummagerPresenters.stubs(:searchable_classes).returns([SearchableTestTopic])
  end

  test "#reindex_all will not request indexing for an instance whose class is not in RummagerPresenters.searchable_classes" do
    class NonExistentClass; end
    RummagerPresenters.stubs(:searchable_classes).returns([NonExistentClass])
    SearchableTestTopic.create!(name: "woo", state: "published")
    Whitehall::SearchIndex.expects(:add).never
    SearchableTestTopic.reindex_all
  end

  test "#reindex_all will respect the scopes it is prefixed with" do
    searchable_test_topic_1 = SearchableTestTopic.create!(name: "woo", state: "published")
    searchable_test_topic_2 = SearchableTestTopic.create!(name: "moo", state: "published")
    Whitehall::SearchIndex.expects(:add).with(searchable_test_topic_1).never
    Whitehall::SearchIndex.expects(:add).with(searchable_test_topic_2)
    SearchableTestTopic.where(name: "moo").reindex_all
  end

  test "#reindex_all will request indexing for each searchable instance" do
    searchable_test_topic_1 = SearchableTestTopic.create!(name: "woo", state: "draft")
    searchable_test_topic_2 = SearchableTestTopic.create!(name: "woo", state: "published")
    Whitehall::SearchIndex.expects(:add).with(searchable_test_topic_1).never
    Whitehall::SearchIndex.expects(:add).with(searchable_test_topic_2)
    SearchableTestTopic.reindex_all
  end

  test "#searchable_instances uses the searchable_options[:only] proc to find instances that can be searched" do
    draft_topic = SearchableTestTopic.create!(name: "woo", state: "draft")
    published_topic = SearchableTestTopic.create!(name: "woo", state: "published")

    searchable_topics = SearchableTestTopic.searchable_instances
    assert searchable_topics.include?(published_topic)
    assert_not searchable_topics.include?(draft_topic)
  end
end
