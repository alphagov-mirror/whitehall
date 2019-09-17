class PublishingApiVanishWorker < PublishingApiWorker
  def perform(content_id, locale)
    check_if_locked_document(content_id: content_id)

    Services.publishing_api.unpublish(
      content_id,
      type: "vanish",
      locale: locale,
    )
  rescue GdsApi::HTTPNotFound, GdsApi::HTTPUnprocessableEntity
    # nothing to do here as we can't unpublish something that doesn't exist
    nil
  end
end
