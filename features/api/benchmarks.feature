Feature: Getting benchmarks from the API by their ID

  Background:
    Given a clean database
    And the database fixtures:
      | fixture                 |
      | metadata                |
      | input_data_source       |
      | input_data_file_set     |
      | input_data_file         |
      | assembly_image_instance |
      | benchmarks              |
      | tasks                   |

  Scenario: Getting a benchmark with no events
    When I get the url "/benchmarks/2f221a18eb86380369570b2ed147d8b4"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id       | "2f221a18eb86380369570b2ed147d8b4"    |
      | complete | false                                 |
      | type     | "illumina_isolate_reference_assembly" |
