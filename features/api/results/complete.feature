Feature: Getting the results for completed benchmarks

  Background:
    Given an empty database without any tables
    And the database fixtures:
      | fixture       |
      | initial_state |

  Scenario Outline: Getting the benchmark results when none have been completed
    When I get the url "/results/complete?format=<name>"
    Then the returned HTTP status code should be "200"
    And the returned HTTP headers should include:
      | header               | value                                                       |
      | Content-Type         | <content-type>                                              |
      | Content-Disposition  | attachment; filename="nucleotides_benchmark_metrics.<name>" |
    And the returned body should be a valid <format> document
    And the returned document should be empty

    Examples:
      | name | format | content-type                   |
      | csv  | CSV    | text/csv;charset=UTF-8         |
      | json | JSON   | application/json;charset=UTF-8 |



  Scenario Outline: Getting results in different states of task completion
    Given the database fixtures:
      | fixture |
      | benchmark_instance/<fix>   |
    When I get the url "/results/complete?format=<name>"
    Then the returned HTTP status code should be "200"
    And the returned HTTP headers should include:
      | header               | value                                                       |
      | Content-Type         | <content-type>                                              |
      | Content-Disposition  | attachment; filename="nucleotides_benchmark_metrics.<name>" |
    And the returned body should be a valid <format> document
    And the returned document should contain <n> entries

    Examples:
      | name | format | content-type                   | n | fix                                              |
      | json | JSON   | application/json;charset=UTF-8 | 0 | one_partially_completed                          |
      | json | JSON   | application/json;charset=UTF-8 | 2 | two_completed_from_two_different_benchmark_types |
      | csv  | CSV    | text/csv;charset=UTF-8         | 0 | one_partially_completed                          |
      | csv  | CSV    | text/csv;charset=UTF-8         | 3 | one_completed                                    |
      | csv  | CSV    | text/csv;charset=UTF-8         | 3 | one_completed_twice                              |
      | csv  | CSV    | text/csv;charset=UTF-8         | 0 | two_failed                                       |
      | csv  | CSV    | text/csv;charset=UTF-8         | 3 | one_completed_with_initial_failure               |
      | csv  | CSV    | text/csv;charset=UTF-8         | 3 | one_completed_and_one_failed                     |


  Scenario Outline: Getting subsets of metrics using URL parameters
    Given the database fixtures:
      | fixture                                                             |
      | benchmark_instance/two_completed_from_two_different_benchmark_types |
    When I get the url "/results/complete?format=csv<params>"
    Then the returned HTTP status code should be "200"
    And the returned HTTP headers should include:
      | header               | value                                                    |
      | Content-Type         | text/csv;charset=UTF-8                                   |
      | Content-Disposition  | attachment; filename="nucleotides_benchmark_metrics.csv" |
    And the returned body should be a valid CSV document
    And the returned document should contain <n> entries

    Examples:
      | n | params                                                               |
      | 6 |                                                                      |
      | 3 | &benchmark_type[]=benchmark_1                                        |
      | 3 | &benchmark_type[]=benchmark_1&benchmark_type[]=benchmark_2           |
      | 0 | &benchmark_type[]=no_data_sets                                       |
      | 2 | &variable[]=produce_task_metric_1                                    |
      | 2 | &variable[]=produce_task_metric_1&variable[]=produce_task_metric_1   |
      | 4 | &variable[]=evaluate_task_metric_1&variable[]=evaluate_task_metric_2 |
      | 1 | &benchmark_type[]=benchmark_1&variable[]=produce_task_metric_1       |


  Scenario: Getting results when some tasks have failed
    Given the database fixtures:
      | fixture                                               |
      | benchmark_instance/one_completed_with_initial_failure |
    When I get the url "/results/complete?format=json"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | 0/biological_sources/0/file_sets/0/files/0/images/0/versions/0/image_tasks/0/metrics/0/value | 1.0 |
