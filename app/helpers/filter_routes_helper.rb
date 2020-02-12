module FilterRoutesHelper
  def announcements_filter_path(*objects)
    announcements_path(path_arguments(objects))
  end

  def publications_filter_path(*objects)
    publications_path(path_arguments(objects))
  end

  def consultations_filter_path(*objects)
    consultations_path(path_arguments(objects))
  end

  def statistical_data_sets_filter_path(*objects)
    statistical_data_sets_path(path_arguments(objects))
  end

  def filter_atom_feed_url
    Whitehall::FeedUrlBuilder.new(
      params.permit(
        :from_date, :page, :per_page, :to_date, :keywords, :locale, :include_world_location_news,
        :official_document_status, :publication_type, :announcement_type, :format,
        :publication_filter_option, :announcement_filter_option, :announcement_type_option,
        taxons: [], subtaxons: [], topical_events: [], topics: [], departments: [], people: [], world_locations: []
      ).to_h.merge(document_type: params[:controller].to_s),
    ).url
  end

  def filter_json_url(args = {})
    url_for(params.except(:utf8, :_).merge(format: "json").merge(args))
  end

protected

  def path_arguments(objects)
    objects.reduce({}) do |out, obj|
      if obj.is_a? Organisation
        out[:departments] = [obj.slug]
      elsif obj.is_a? Topic
        out[:topics] = [obj.slug]
      elsif obj.is_a? TopicalEvent
        out[:topical_events] = [obj.slug]
      elsif obj.is_a? WorldLocation
        out[:world_locations] = [obj.slug]
      else
        out = out.merge(obj)
      end
      out
    end
  end
end
