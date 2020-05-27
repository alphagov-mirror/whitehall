edition_translation_data = {
  698_000 => %w[cy en],
  665_884 => %w[cy en],
  641_072 => %w[cy en],
  647_249 => %w[en ja ko zh],
}

edition_translation_data.each do |edition_id, locales|
  edition = Edition.find_by(id: edition_id)
  next unless edition

  edition_translation_locales = edition.translations.map(&:locale).map(&:to_s)
  locales.each do |locale|
    next if edition_translation_locales.include?(locale)

    alternative_url = Whitehall::UrlMaker.new.public_document_url(edition)
    explanation = "This translation is no longer available. You can find the original version of this content at [#{alternative_url}](#{alternative_url})"
    PublishingApiGoneWorker.perform_async(edition.content_id, nil, explanation, locale)
  end
end
