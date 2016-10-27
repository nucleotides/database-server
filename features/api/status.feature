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
    And the JSON at "summary" should have the following:
      | n_files_generated                     | 0   |
      | n_metrics_collected                   | 0   |
      | total_cpu_time_in_days                | 0.0 |
      | total_wall_clock_time_in_days         | 0.0 |
      | length_of_all_contigs_generated_in_gb | 0.0 |
      | n_contigs_generated                   | 0.0 |
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
      | is_executed         | false |
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
      | is_executed         | false |
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
      | is_executed         | false |
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
      | is_executed         | false |
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
      | is_executed         | false |



  Scenario: Getting the current status when some tasks have been completed
    Given the database fixtures:
      | fixture                                           |
      | testing_data/partial_benchmark_instance_completed |
    When I get the url "/status.json"
    Then the returned HTTP status code should be "200"
    And the returned HTTP headers should include:
      | header       | value                          |
      | Content-Type | application/json;charset=UTF-8 |
    And the returned body should be a valid JSON document
    And the JSON at "summary" should have the following:
      | n_files_generated                     | 0        |
      | n_metrics_collected                   | 2        |
      | total_cpu_time_in_days                | 11574.07 |
      | total_wall_clock_time_in_days         | 11574.07 |
      | length_of_all_contigs_generated_in_gb | 0.0      |
      | n_contigs_generated                   | 0.0      |
    And the JSON at "tasks/all" should have the following:
      | n                   | 18    |
      | n_successful        | 3     |
      | n_errorful          | 0     |
      | n_outstanding       | 15    |
      | n_executed          | 3     |
      | percent_successful  | 16.67 |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 83.33 |
      | percent_executed    | 16.67 |
      | is_executed         | false |
    And the JSON at "tasks/produce" should have the following:
      | n                   | 6     |
      | n_successful        | 1     |
      | n_errorful          | 0     |
      | n_outstanding       | 5     |
      | n_executed          | 1     |
      | percent_successful  | 16.67 |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 83.33 |
      | percent_executed    | 16.67 |
      | is_executed         | false |
    And the JSON at "tasks/evaluate" should have the following:
      | n                   | 12    |
      | n_successful        | 2     |
      | n_errorful          | 0     |
      | n_outstanding       | 10    |
      | n_executed          | 2     |
      | percent_successful  | 16.67 |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 83.33 |
      | percent_executed    | 16.67 |
      | is_executed         | false |
    And the JSON at "benchmarks/benchmark_1" should have the following:
      | n                   | 12    |
      | n_successful        | 3     |
      | n_errorful          | 0     |
      | n_outstanding       | 9     |
      | n_executed          | 3     |
      | percent_successful  | 25.0  |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 75.0  |
      | percent_executed    | 25.0  |
      | is_executed         | false |
    And the JSON at "benchmarks/all" should have the following:
      | n                   | 18    |
      | n_successful        | 3     |
      | n_errorful          | 0     |
      | n_outstanding       | 15    |
      | n_executed          | 3     |
      | percent_successful  | 16.67 |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 83.33 |
      | percent_executed    | 16.67 |
      | is_executed         | false |

  Scenario: Getting the current status when a benchmark type has been completed
    Given the database fixtures:
      | fixture                                   |
      | testing_data/one_benchmark_type_completed |
    When I get the url "/status.json"
    Then the returned HTTP status code should be "200"
    And the returned HTTP headers should include:
      | header       | value                          |
      | Content-Type | application/json;charset=UTF-8 |
    And the returned body should be a valid JSON document
    And the JSON at "summary" should have the following:
      | n_files_generated                     | 4        |
      | n_metrics_collected                   | 12       |
      | total_cpu_time_in_days                | 46296.30 |
      | total_wall_clock_time_in_days         | 46296.30 |
      | length_of_all_contigs_generated_in_gb | 40.0     |
      | n_contigs_generated                   | 0.0      |
    And the JSON at "tasks/all" should have the following:
      | n                   | 18    |
      | n_successful        | 12    |
      | n_errorful          | 0     |
      | n_outstanding       | 6     |
      | n_executed          | 12    |
      | percent_successful  | 66.67 |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 33.33 |
      | percent_executed    | 66.67 |
      | is_executed         | false |
    And the JSON at "tasks/produce" should have the following:
      | n                   | 6     |
      | n_successful        | 4     |
      | n_errorful          | 0     |
      | n_outstanding       | 2     |
      | n_executed          | 4     |
      | percent_successful  | 66.67 |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 33.33 |
      | percent_executed    | 66.67 |
      | is_executed         | false |
    And the JSON at "tasks/evaluate" should have the following:
      | n                   | 12    |
      | n_successful        | 8     |
      | n_errorful          | 0     |
      | n_outstanding       | 4     |
      | n_executed          | 8     |
      | percent_successful  | 66.67 |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 33.33 |
      | percent_executed    | 66.67 |
      | is_executed         | false |
    And the JSON at "benchmarks/benchmark_1" should have the following:
      | n                   | 12    |
      | n_successful        | 12    |
      | n_errorful          | 0     |
      | n_outstanding       | 0     |
      | n_executed          | 12    |
      | percent_successful  | 100.0 |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 0.0   |
      | percent_executed    | 100.0 |
      | is_executed         | true  |
    And the JSON at "benchmarks/all" should have the following:
      | n                   | 18    |
      | n_successful        | 12    |
      | n_errorful          | 0     |
      | n_outstanding       | 6     |
      | n_executed          | 12    |
      | percent_successful  | 66.67 |
      | percent_errorful    | 0.0   |
      | percent_outstanding | 33.33 |
      | percent_executed    | 66.67 |
      | is_executed         | false |
