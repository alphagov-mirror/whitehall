natural_england = Organisation.find_by!(slug: "natural-england")
rpa = Organisation.find_by!(slug: "rural-payments-agency")

docs_with_lead = EditionOrganisation.where(organisation: natural_england, lead: true).map(&:edition).compact.map(&:document).uniq
docs_with_support = EditionOrganisation.where(organisation: natural_england, lead: false).map(&:edition).compact.map(&:document).uniq

docs_with_lead.each do |document|
  next if document.document_type == "CorporateInformationPage"

  edition = document.latest_edition
  edition.read_consultation_principles = true if document.document_type == "Consultation"
  orgs = edition.lead_organisations.to_a

  orgs << rpa unless orgs.include? rpa
  orgs.delete natural_england

  edition.lead_organisations = orgs
  edition.save!(validate: false)
rescue StandardError => e
  puts "#{document.slug}: #{e.class}, #{e.message}"
end

docs_with_support.each do |document|
  next if document.document_type == "CorporateInformationPage"

  edition = document.latest_edition
  edition.read_consultation_principles = true if document.document_type == "Consultation"
  orgs = edition.supporting_organisations.to_a

  # handle the case where NE is the lead and RPA the support (or vice versa)
  orgs << rpa unless orgs.include?(rpa) || edition.lead_organisations.include?(rpa)
  orgs.delete natural_england

  edition.supporting_organisations = orgs
  edition.save!(validate: false)
rescue StandardError => e
  puts "#{document.slug}: #{e.class}, #{e.message}"
end
