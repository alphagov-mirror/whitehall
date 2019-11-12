module PublishingApi
  class PersonPresenter
    attr_accessor :item
    attr_accessor :update_type

    def initialize(item, update_type: nil)
      self.item = item
      self.update_type = update_type || "major"
    end

    def content_id
      item.content_id
    end

    def content
      content = BaseItemPresenter.new(
        item,
        title: item.name,
        update_type: update_type,
      ).base_attributes

      content.merge!(
        description: nil,
        details: details,
        document_type: "person",
        public_updated_at: item.updated_at,
        rendering_app: Whitehall::RenderingApp::WHITEHALL_FRONTEND,
        schema_name: "person",
      )
      content.merge!(PayloadBuilder::PolymorphicPath.for(item))
    end

    def links
      {
        ordered_current_appointments: item.current_role_appointments.pluck(:content_id).compact,
        ordered_previous_appointments: item.previous_role_appointments.pluck(:content_id).compact,
      }
    end

    def details
      details_hash = {}

      if item.image_url(:s465)
        details_hash[:image] = { url: item.image_url(:s465), alt_text: item.name }
      end

      details_hash.merge(
        full_name: item.full_name,
        privy_counsellor: item.privy_counsellor?,
        body: body,
      )
    end

    def body
      Whitehall::GovspeakRenderer.new.govspeak_to_html(item.biography || "")
    end
  end
end
