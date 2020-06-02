require "gds_api/router"

old_slug = "flexibly-accessed-pension-payment-repayment-claim-tax-year-2015-2016-p55"
new_slug = "flexibly-accessed-pension-payment-repayment-claim-tax-year-p55"

document = Document.find_by(slug: old_slug)
if document
  puts "Changing document slug #{old_slug} -> #{new_slug}"
  document.update!(slug: new_slug)
  PublishingApiDocumentRepublishingWorker.perform_async(document.id)
else
  puts "Can't find document with slug of #{old_slug}"
end
