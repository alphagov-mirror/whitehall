require "test_helper"

class AnnouncementsControllerTest < ActionController::TestCase
  include ActionView::Helpers::DateHelper

  should_be_a_public_facing_controller
  should_return_json_suitable_for_the_document_filter :news_article
  should_return_json_suitable_for_the_document_filter :speech

  test "index shows a mix of news and speeches" do
    announced_today = [create(:published_news_article), create(:published_speech)]

    get :index

    assert_select_object announced_today[0]
    assert_select_object announced_today[1]
  end

  test "index sets Cache-Control: max-age to the time of the next scheduled publication" do
    user = login_as(:departmental_editor)
    news = create(:draft_news_article, scheduled_publication: Time.zone.now + Whitehall.default_cache_max_age * 2)
    news.schedule_as(user, force: true)

    Timecop.freeze(Time.zone.now + Whitehall.default_cache_max_age * 1.5) do
      get :index
    end

    assert_cache_control("max-age=#{Whitehall.default_cache_max_age/2}")
  end

  test "index shows which type a record is" do
    announced_today = [
      create(:published_news_article),
      create(:published_speech),
      create(:published_speech, speech_type: SpeechType::WrittenStatement),
    ]

    get :index

    assert_select_object announced_today[0] do
      assert_select ".announcement_type", text: "News article"
    end
    assert_select_object announced_today[1] do
      assert_select ".announcement_type", text: "Speech"
    end
    assert_select_object announced_today[2] do
      assert_select ".announcement_type", text: "Statement to parliament"
    end
  end

  test "index shows the date on which a speech was delivered" do
    delivered_on = Date.parse("1999-12-31")
    speech = create(:published_speech, delivered_on: delivered_on)

    get :index

    assert_select_object(speech) do
     assert_select "abbr.delivered_on[title=?]", delivered_on.iso8601
    end
  end

  test "index shows the time when a news article was first published" do
    first_published_at = Time.zone.parse("2001-01-01 01:01")
    news_article = create(:published_news_article, published_at: first_published_at)

    get :index

    assert_select_object(news_article) do
     assert_select "abbr.first_published_at[title=?]", first_published_at.iso8601
    end
  end

  test "index shows related organisations for each type of article" do
    first_org = create(:organisation, name: 'first-org', acronym: "FO")
    second_org = create(:organisation, name: 'second-org', acronym: "SO")
    news_article = create(:published_news_article, published_at: 4.days.ago, organisations: [first_org, second_org])
    role = create(:ministerial_role, organisations: [second_org])
    role_appointment = create(:ministerial_role_appointment, role: role)
    speech = create(:published_speech, delivered_on: 5.days.ago, role_appointment: role_appointment)

    get :index

    assert_select_object news_article do
      assert_select ".organisations", text: "#{first_org.acronym} and #{second_org.acronym}", count: 1
    end

    assert_select_object speech do
      assert_select ".organisations", text: second_org.acronym, count: 1
    end
  end

  test "index shows articles in reverse chronological order" do
    oldest = create(:published_speech, delivered_on: 5.days.ago)
    newest = create(:published_news_article, published_at: 4.days.ago)

    get :index

    assert_select "#{record_css_selector(newest)} + #{record_css_selector(oldest)}"
  end

  test "index shows articles in chronological order if date filter is 'after' a given date" do
    oldest = create(:published_speech, delivered_on: 5.days.ago)
    newest = create(:published_news_article, published_at: 4.days.ago)

    get :index, direction: 'after', date: 6.days.ago.to_s

    assert_select "#{record_css_selector(oldest)} + #{record_css_selector(newest)}"
  end

  def assert_documents_appear_in_order_within(containing_selector, expected_documents)
    articles = css_select "#{containing_selector} tr.document-row"
    expected_document_ids = expected_documents.map { |doc| dom_id(doc) }
    actual_document_ids = articles.map { |a| a["id"] }
    assert_equal expected_document_ids, actual_document_ids
  end

  test "index shows only the first 20 news articles or speeches" do
    news = (0...15).map { |n| create(:published_news_article, published_at: n.days.ago) }
    speeches = (15...25).map { |n| create(:published_speech, delivered_on: n.days.ago) }

    get :index

    assert_documents_appear_in_order_within("#announcements-container", news + speeches[0...5])
    speeches[5..10].each do |speech|
      refute_select_object(speech)
    end
  end

  test "index shows the requested page" do
    news = (0...15).map { |n| create(:published_news_article, published_at: n.days.ago) }
    speeches = (15...25).map { |n| create(:published_speech, delivered_on: n.days.ago) }

    get :index, page: 2

    assert_documents_appear_in_order_within("#announcements-container", speeches[5..10])
    (news + speeches[0...5]).each do |speech|
      refute_select_object(speech)
    end
  end

  test "index generates an atom feed for the current filter" do
    org = create(:organisation, name: "org-name")

    get :index, format: :atom, departments: [org.to_param]

    assert_select_atom_feed do
      assert_select 'feed > id', 1
      assert_select 'feed > title', 1
      assert_select 'feed > author, feed > entry > author'
      assert_select 'feed > updated', 1
      assert_select 'feed > link[rel=?][type=?][href=?]', 'self', 'application/atom+xml',
                    publications_url(format: :atom, departments: [org.to_param]), 1
      assert_select 'feed > link[rel=?][type=?][href=?]', 'alternate', 'text/html', root_url, 1
    end
  end

  test "index generates an atom feed entries for announcments matching the current filter" do
    org = create(:organisation, name: "org-name")
    other_org = create(:organisation, name: "other-org")
    create(:published_news_article, organisations: [org])
    create(:published_speech, organisations: [other_org])

    get :index, format: :atom, departments: [org.to_param]

    assert_select_atom_feed do
      assert_select 'feed > entry', count: 1 do |entries|
        entries.each do |entry|
          assert_select entry, 'entry > id', 1
          assert_select entry, 'entry > published', 1
          assert_select entry, 'entry > updated', 1
          assert_select entry, 'entry > link[rel=?][type=?]', 'alternate', 'text/html', 1
          assert_select entry, 'entry > title', 1
          assert_select entry, 'entry > content[type=?]', 'html', 1
        end
      end
    end
  end

  test 'index atom feed should return a valid feed if there are no matching documents' do
    get :index, format: :atom

    assert_select_atom_feed do
      assert_select 'feed > updated', text: Time.zone.now.iso8601
      assert_select 'feed > entry', count: 0
    end
  end
end
