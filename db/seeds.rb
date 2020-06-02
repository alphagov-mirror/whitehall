# The test environment expects an empty test database. These seeds are used
# to set up the minimum for a dev environment and are used with
# https://github.com/alphagov/publishing-e2e-tests
return if Rails.env.test?

if User.where(name: "Test user").blank?
  gds_organisation_id = "af07d5a5-df63-4ddc-9383-6a666845ebe9"
  User.create!(
    name: "Test user",
    permissions: ["signin", "GDS Admin", "GDS Editor", "Managing Editor", "Export data"],
    organisation_content_id: gds_organisation_id,
    organisation_slug: "test-organisation",
  )
end

if Organisation.where(name: "HM Revenue & Customs").blank?
  Organisation.skip_callback(:commit, :after, :publish_to_publishing_api)
  Organisation.create!(
    name: "HM Revenue & Customs",
    slug: "hm-revenue-customs",
    acronym: "HRMC",
    organisation_type_key: :other,
    logo_formatted_name: "Test",
    content_id: "6667cce2-e809-4e21-ae09-cb0bdc1ddda3",
  )
end

if Organisation.where(name: "Test Organisation").blank?
  Organisation.create!(
    name: "Test Organisation",
    slug: "test-organisation",
    acronym: "TO",
    organisation_type_key: :other,
    logo_formatted_name: "Test",
  )
end

if Government.where(name: "Test Government").blank?
  Government.skip_callback(:commit, :after, :publish_to_publishing_api)
  Government.create!(
    name: "Test Government",
    start_date: Time.zone.local(2001, 1, 1),
  )
end

if Topic.where(name: "Test Policy Area").blank?
  Topic.skip_callback(:commit, :after, :publish_to_publishing_api)
  Topic.create!(
    name: "Test Policy Area",
    description: "Test Policy Area Description",
  )
end

if WorldLocation.where(name: "Test World Location").blank?
  WorldLocation.create!(
    name: "Test World Location",
    world_location_type_id: 1,
  )
end
