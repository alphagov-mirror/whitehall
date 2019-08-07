class DocumentCollectionGroupMembership < ApplicationRecord
  BANNED_DOCUMENT_TYPES = %w[DocumentCollection].freeze
  include LockedDocumentConcern

  belongs_to :document,
             inverse_of: :document_collection_group_memberships,
             optional: true
  belongs_to :non_whitehall_link,
             class_name: 'DocumentCollectionNonWhitehallLink',
             inverse_of: :document_collection_group_memberships,
             optional: true
  belongs_to :document_collection_group, inverse_of: :memberships

  before_create :assign_ordering

  before_save { check_if_locked_document(document: document) if document }

  validates :document_collection_group, presence: true
  validate :document_is_of_allowed_type, if: -> { document.present? }
  validate :presence_of_document_or_non_whitehall_link

private

  def assign_ordering
    self.ordering = document_collection_group.documents.size + 1
  end

  def document_is_of_allowed_type
    if document && BANNED_DOCUMENT_TYPES.include?(document.document_type)
      errors.add(:document, "cannot be a #{document.humanized_document_type}")
    end
  end

  def presence_of_document_or_non_whitehall_link
    if document && non_whitehall_link
      errors.add(:base, "cannot be associated with a document and an non-whitehall link")
    end

    if !document && !non_whitehall_link
      errors.add(:base, "must be associated with a document or an non-whitehall link")
    end
  end
end
