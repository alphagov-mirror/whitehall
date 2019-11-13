require "test_helper"

class Admin::Export::DocumentControllerTest < ActionController::TestCase
  test "show responds with JSON representation of a document" do
    document = stub_record(:document, id: 1, slug: "some-document")
    Document.stubs(:find).with(document.id.to_s).returns(document)

    login_as :export_data_user
    get :show, params: { id: document.id }, format: "json"
    assert_equal "some-document", json_response["slug"]
  end

  test "shows forbidden if user does not have export data permission" do
    login_as :world_editor
    get :show, params: { id: "1" }, format: "json"
    assert_response :forbidden
  end

  test "index responds with document information for a lead org and type" do
    org = create(:organisation)
    news_story = create(
      :news_article,
      organisations: [org],
      news_article_type: NewsArticleType::NewsStory,
    )

    login_as :export_data_user

    get :index, params: { lead_organisation: org.content_id,
                          type: "NewsArticle" }, format: "json"

    expected_response =
      {
        "documents" => [{
          "document_id" => news_story.document_id,
          "document_information" => {
            "locales" => %w[en],
            "subtypes" => %w[news_story],
            "lead_organisations" => [org.content_id],
          },
        }],
        "page_number" => 1,
        "page_count" => 1,
        "_response_info" => { "status" => "ok" },
    }

    assert_equal expected_response, json_response
  end


  test "doesnt return the document where the latest edition is not associated with lead org" do
    published_edition_org = create(:organisation)
    draft_edition_org = create(:organisation)
    document = create(:document)
    create(
      :news_article,
      :published,
      document: document,
      organisations: [published_edition_org],
      news_article_type: NewsArticleType::NewsStory,
    )

    create(
      :news_article,
      :draft,
      document: document,
      organisations: [draft_edition_org],
      news_article_type: NewsArticleType::NewsStory,
    )

    login_as :export_data_user

    get :index, params: { lead_organisation: published_edition_org.content_id,
                          type: "NewsArticle" }, format: "json"

    expected_response =
      {
        "documents" => [],
        "page_number" => 1,
        "page_count" => 0,
        "_response_info" => { "status" => "ok" },
    }

    assert_equal expected_response, json_response
  end

  test "lock returns forbidden if user does not have export data permission" do
    login_as :world_editor
    post :lock, params: { id: "1" }, format: "json"
    assert_response :forbidden
  end

  test "locks document" do
    document = create(:document)
    login_as :export_data_user

    post :lock, params: { id: document.id }, format: "json"

    assert document.reload.locked
    assert_response :no_content
  end

  test "unlock returns forbidden if user does not have export data permission" do
    login_as :world_editor
    post :unlock, params: { id: "1" }, format: "json"
    assert_response :forbidden
  end

  test "unlocks document" do
    document = create(:document, locked: true)
    login_as :export_data_user

    post :unlock, params: { id: document.id }, format: "json"

    refute document.reload.locked
    assert_response :no_content
  end

  test "marks locked document as migrated" do
    document = create(:document, locked: true)
    login_as :export_data_user

    post :migrated, params: { id: document.id }, format: "json"

    assert_response :no_content
  end

  test "does not mark unlocked document as migrated" do
    document = create(:document, locked: false)
    login_as :export_data_user

    post :migrated, params: { id: document.id }, format: "json"

    assert_response :unprocessable_entity
  end
end
