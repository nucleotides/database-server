Feature: Getting the current status of the benchmarking

  Background:
    Given an empty database without any tables
    And the database fixtures:
      | fixture                    |
      | testing_data/initial_state |

  Scenario: Getting the current status when no tasks have been completed
    When I get the url "/status.json"
    Then the returned HTTP status code should be "200"
    And the returned HTTP headers should include:
      | header       | value                          |
      | Content-Type | application/json;charset=UTF-8 |
    And the returned body should be a valid JSON document
