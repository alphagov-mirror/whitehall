# encoding: utf-8

def find_corporation_information_page_type_by_title(title)
  I18n.with_locale(:en) {
    CorporateInformationPageType.all.detect { |type| type.title(Organisation.new) == title }
  }
end

Given(/^I add a "([^"]*)" corporate information page to "([^"]*)" with body "([^"]*)"$/) do |page_type, org_name, body|
  organisation = Organisation.find_by(name: org_name)
  visit admin_organisation_path(organisation)
  click_link "Corporate information pages"
  click_link "New corporate information page"
  fill_in "Body", with: body
  select page_type, from: "Type"
  click_button "Save"
end

Given(/^I force-publish the "([^"]*)" corporate information page for the organisation "([^"]*)"$/) do |page_type, org_name|
  organisation = Organisation.find_by(name: org_name)
  info_page = organisation.corporate_information_pages.last
  stub_publishing_api_links_with_taxons(info_page.content_id, ["a-taxon-content-id"])
  visit admin_organisation_path(organisation)
  click_link "Corporate information pages"
  click_link page_type
  publish(force: true)
end

When(/^I click the "([^"]*)" link$/) do |link_text|
  click_link link_text
end

Then(/^I should see the text "([^"]*)"$/) do |text|
  assert_text text, normalize_ws: true
end

When(/^I add a "([^"]*)" corporate information page to the worldwide organisation$/) do |page_type|
  worldwide_organisation = WorldwideOrganisation.last
  visit admin_worldwide_organisation_path(worldwide_organisation)
  click_link "Corporate information pages"
  click_link "New corporate information page"
  fill_in "Body", with: "This is a new #{page_type} page"
  select page_type, from: "Type"
  click_button "Save"
end

When(/^I force-publish the "([^"]*)" corporate information page for the worldwide organisation "([^"]*)"$/) do |page_type, org_name|
  organisation = WorldwideOrganisation.find_by(name: org_name)
  info_page = organisation.corporate_information_pages.last
  stub_publishing_api_links_with_taxons(info_page.content_id, ["a-taxon-content-id"])
  visit admin_worldwide_organisation_path(organisation)
  click_link "Corporate information pages"
  click_link page_type
  publish(force: true)
end

Then(/^I should see the corporate information on the public worldwide organisation page$/) do
  worldwide_organisation = WorldwideOrganisation.last
  info_page = worldwide_organisation.corporate_information_pages.last
  visit worldwide_organisation_path(worldwide_organisation)
  assert_text info_page.title
  click_link info_page.title
  assert_text info_page.body
end

When(/^I translate the "([^"]*)" corporate information page for the worldwide organisation "([^"]*)"$/) do |corp_page, worldwide_org|
  worldwide_organisation = WorldwideOrganisation.find_by(name: worldwide_org)
  visit admin_worldwide_organisation_path(worldwide_organisation)
  click_link "Corporate information pages"
  click_link corp_page
  click_link "open-add-translation-modal"
  select "Français", from: "Locale"
  click_button "Add translation"
  fill_in "Summary", with: "Le summary"
  fill_in "Body", with: "Le body"
  click_on "Save"
end

Then(/^I should be able to read the translated "([^"]*)" corporate information page for the worldwide organisation "([^"]*)" on the site$/) do |corp_page, worldwide_org|
  worldwide_organisation = WorldwideOrganisation.find_by(name: worldwide_org)
  visit worldwide_organisation_path(worldwide_organisation)

  click_link corp_page
  click_link "Français"

  assert_selector ".description", text: "Le summary"
  assert_selector ".body", text: "Le body"
end

When(/^I translate the "([^"]*)" corporate information page for the organisation "([^"]*)"$/) do |corp_page, organisation_name|
  organisation = Organisation.find_by(name: organisation_name)
  visit admin_organisation_path(organisation)
  click_link "Corporate information pages"
  click_link corp_page
  click_link "open-add-translation-modal"
  select "Français", from: "Locale"
  click_button "Add translation"
  fill_in "Summary", with: "Le summary"
  fill_in "Body", with: "Le body"
  click_on "Save"
end

Then(/^I should be able to read the translated "([^"]*)" corporate information page for the organisation "([^"]*)" on the site$/) do |corp_page, organisation_name|
  organisation = Organisation.find_by(name: organisation_name)
  visit organisation_path(organisation)

  click_link corp_page
  click_link "Français"

  assert_selector ".description", text: "Le summary"
  assert_selector ".body", text: "Le body"
end

Given(/^my organisation has a "(.*?)" corporate information page$/) do |page_title|
  @user.organisation ||= create(:organisation)
  stub_organisation_in_content_store("Organisation name", @user.organisation.base_path)
  page_type = find_corporation_information_page_type_by_title(page_title)
  create(:corporate_information_page,
         corporate_information_page_type: page_type,
         organisation: @user.organisation)
end

Then(/^I should be able to add attachments to the "(.*?)" corporate information page$/) do |page_title|
  page_type = find_corporation_information_page_type_by_title(page_title)
  page = @user.organisation.corporate_information_pages.find_by_corporate_information_page_type_id(page_type.id)
  stub_publishing_api_links_with_taxons(page.content_id, ["a-taxon-content-id"])
  attachment = upload_pdf_to_corporate_information_page(page)
  insert_attachment_markdown_into_corporate_information_page_body(attachment, page)
  Attachment.last.attachment_data.uploaded_to_asset_manager!
  publish(force: true)
  check_attachment_appears_on_corporate_information_page(attachment, page)
end
