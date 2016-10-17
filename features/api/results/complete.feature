Feature: Getting the results for completed benchmarks

  Background:
    Given an empty database without any tables
    And the database fixtures:
      | fixture          |
      | testing_db_state |

  Scenario Outline: Getting the benchmark results when none have been completed
    When I get the url "/results/complete?format=<name>"
    And the returned HTTP headers should include:
      | header       | value          |
      | Content-Type | <content-type> |
    And the returned body should be a valid <format> document
    And the returned document should be empty

    Examples:
      | name | format | content-type                   |
      | csv  | CSV    | text/csv;charset=UTF-8         |
      | json | JSON   | application/json;charset=UTF-8 |



  Scenario Outline: Getting the benchmark results when a single image task have been completed
    Given the database fixtures:
      | fixture                                |
      | all_tasks_completed_for_image_1_task_1 |
    When I get the url "/results/complete?format=<name>"
    Then the returned HTTP status code should be "200"
    And the returned HTTP headers should include:
      | header       | value          |
      | Content-Type | <content-type> |
    And the returned body should be a valid <format> document
    And the returned document should not be empty
    And the returned document should contain <n> entries

    Examples:
      | name | format | content-type                   | n |
      | csv  | CSV    | text/csv;charset=UTF-8         | 2 |
      | json | JSON   | application/json;charset=UTF-8 | 1 |
