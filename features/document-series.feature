Feature: Grouping documents into series
  As an organisation,
  I want to present regularly published documents as series
  So that my users can more easily find earlier publications of the same type

  Background:
    Given I am a writer in the organisation "Government Department"

  @javascript
  Scenario: Admin creats a document series and previews it.
    Given a published document "Wombats of Wimbledon" exists
    When I draft a new document series called "Wildlife of Wimbledon Common"
    And I add the document "Wombats of Wimbledon" to the document series
    Then I can preview the document series
    And I see that the document "Wombats of Wimbledon" is part of the document series

  @javascript
  Scenario: Removing documents from a series
    Given a published publication called "May 2012 Update" in the document series "Monthly Updates"
    And I'm editing the document series "Monthly Updates"
    When I remove the document "May 2012 Update" from the document series
    And I preview the document series
    Then I see that the document "May 2012 Update" is not part of the document series

  Scenario: Documents should link back to their series
    Given a published publication called "May 2012 Update" in the document series "Monthly Updates"
    When I visit the publication "May 2012 Update"
    Then I should see links back to the series
