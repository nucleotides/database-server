Feature: Getting all incomplete tasks from the API

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

  Scenario: Listing all tasks for an incomplete benchmark
    When I get the url "/tasks/show.json"
    Then the returned HTTP status code should be "200"
    And the JSON should be [1,3,5,7,9,11]
