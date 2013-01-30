require 'test_helper'

class TopicalEventTestTest < ActiveSupport::TestCase
  test "a new news article is not featured" do
    topical_event = create(:topical_event)
    news_article = build(:news_article)
    refute topical_event.featured?(news_article)
  end

  test "a featured news article is featured" do
    topical_event = create(:topical_event)
    news_article = create(:published_news_article)
    image = create(:classification_featuring_image_data)
    topical_event.feature(edition_id: news_article.id, alt_text: "A thing", image: image)
    featuring = topical_event.featuring_of(news_article)
    assert featuring
    assert_equal 1, featuring.ordering
    assert topical_event.featured?(news_article)
  end

  test "a featured news article is no longer featured when it is archived" do
    topical_event = create(:topical_event)
    news_article = create(:published_news_article)
    image = create(:classification_featuring_image_data)
    topical_event.feature(edition_id: news_article.id, alt_text: "A thing", image: image)
    news_article.archive!

    featuring = topical_event.featuring_of(news_article)
    refute featuring
    refute topical_event.featured?(news_article)
  end

  test '#featured_editions returns featured editions by ordering' do
    topical_event = create(:topical_event)
    alpha = topical_event.feature(edition_id: create(:edition, title: "Alpha").id, ordering: 1, alt_text: 'A thing', image: create(:classification_featuring_image_data))
    beta = topical_event.feature(edition_id: create(:published_news_article, title: "Beta").id, ordering: 2, alt_text: 'A thing', image: create(:classification_featuring_image_data))
    gamma = topical_event.feature(edition_id: create(:published_news_article, title: "Gamma").id, ordering: 3, alt_text: 'A thing', image: create(:classification_featuring_image_data))
    delta = topical_event.feature(edition_id: create(:published_news_article, title: "Delta").id, ordering: 0, alt_text: 'A thing', image: create(:classification_featuring_image_data))

    assert_equal [delta.edition, beta.edition, gamma.edition], topical_event.featured_editions
  end

  test '#featured_editions includes the newly published version of a featured edition, but not the original' do
    topical_event = create(:topical_event)
    old_version = topical_event.feature(edition_id: create(:published_news_article, title: "Gamma").id, ordering: 3, alt_text: 'A thing', image: create(:classification_featuring_image_data)).edition

    editor = create(:departmental_editor)
    new_version = old_version.create_draft(editor)
    new_version.change_note = 'New stuffs!'
    new_version.save
    new_version.publish_as(editor, force: true)

    refute topical_event.featured_editions.include?(old_version)
    assert topical_event.featured_editions.include?(new_version)
  end
end