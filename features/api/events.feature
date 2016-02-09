Feature: Posting and getting events from the API

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

  Scenario: Posting an unsuccessful event
    When I post to "/events" with the data:
      """
      {"task"    : 1,
       "success" : false }
      """
    Then the returned HTTP status code should be "201"

  Scenario: Getting an unsuccessful event
    Given I successfully post to "/events" with the data:
      """
      {"task"    : 1,
       "success" : false }
      """
    When I get the url "/events/1"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id           | 1           |
      | task         | 1           |
      | success      | false       |
