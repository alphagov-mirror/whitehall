class TaxonsToLegacyAssociationsTagging
  def call(edition:, user:, selected_taxons:)
    # Only perform the taxon based tagging for content with no
    # existing legacy associations, to avoid overriding human tagging
    # decisions
    return false if tagged_to_specialist_sectors?(edition)

    legacy_associations_from_mappping = legacy_mapping_for_taxons(selected_taxons)

    return false if legacy_associations_from_mappping.empty?

    legacy_associations_by_document_type = legacy_associations_from_mappping
                                             .group_by do |legacy_association|
      legacy_association["document_type"]
    end

    legacy_associations_by_document_type.each do |document_type, legacy_associations|
      content_ids = legacy_associations.map do |legacy_association|
        legacy_association["content_id"]
      end

      next unless document_type == "topic"

      # This is inperfect, as the primary specialist sector tag is
      # being set in an arbitrary manor. But, this mapping function
      # is only a temporary thing while the specialist sectors still
      # exist.

      primary, *secondary = content_ids

      edition.primary_specialist_sector_tag = primary
      edition.secondary_specialist_sector_tags = secondary
    end

    updater = Whitehall.edition_services.draft_updater(edition)

    if updater.can_perform? && edition.save_as(user)
      updater.perform!
    end
  end

private

  def legacy_mapping_for_taxons(selected_taxons)
    Taxonomy::Mapping
      .new
      .legacy_mapping_for_taxons(selected_taxons)
  end

  def tagged_to_specialist_sectors?(edition)
    edition.respond_to?(:specialist_sectors) && edition.specialist_sectors.any?
  end
end
