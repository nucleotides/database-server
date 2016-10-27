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
    And the JSON at "tasks/all" should have the following:
      | n                   | 18    |
      | date_of_most_recent | null  |
      | n_successful        | 0     |
      | n_errorful          | 0     |
      | n_outstanding       | 18    |
      | n_executed          | 0     |
      | percent_successful  | 0.0   |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 100.0 |
      | percent_executed    | 0.0   |
    And the JSON at "tasks/produce" should have the following:
      | n                   | 6     |
      | date_of_most_recent | null  |
      | n_successful        | 0     |
      | n_errorful          | 0     |
      | n_outstanding       | 6     |
      | n_executed          | 0     |
      | percent_successful  | 0.0   |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 100.0 |
      | percent_executed    | 0.0   |
    And the JSON at "tasks/evaluate" should have the following:
      | n                   | 12    |
      | date_of_most_recent | null  |
      | n_successful        | 0     |
      | n_errorful          | 0     |
      | n_outstanding       | 12    |
      | n_executed          | 0     |
      | percent_successful  | 0.0   |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 100.0 |
      | percent_executed    | 0.0   |
    And the JSON at "benchmarks/benchmark_1" should have the following:
      | n                   | 12    |
      | date_of_most_recent | null  |
      | n_successful        | 0     |
      | n_errorful          | 0     |
      | n_outstanding       | 12    |
      | n_executed          | 0     |
      | percent_successful  | 0.0   |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 100.0 |
      | percent_executed    | 0.0   |
    And the JSON at "benchmarks/all" should have the following:
      | n                   | 18    |
      | date_of_most_recent | null  |
      | n_successful        | 0     |
      | n_errorful          | 0     |
      | n_outstanding       | 18    |
      | n_executed          | 0     |
      | percent_successful  | 0.0   |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 100.0 |
      | percent_executed    | 0.0   |
