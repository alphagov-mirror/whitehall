module Edition::BrexitNoDealContentNoticeLinks
  extend ActiveSupport::Concern

  included do
    has_many :brexit_no_deal_content_notice_links, foreign_key: "edition_id", dependent: :destroy

    accepts_nested_attributes_for :brexit_no_deal_content_notice_links, allow_destroy: true, reject_if: :all_blank
  end
end
