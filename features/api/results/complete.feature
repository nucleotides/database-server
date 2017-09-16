Feature: Getting the results for completed benchmarks

  Background:
    Given an empty database without any tables
    And the database fixtures:
      | fixture                    |
      | testing_data/initial_state |

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
      | fixture            |
      | testing_data/<fix> |
    When I get the url "/results/complete?format=<name>"
    Then the returned HTTP status code should be "200"
    And the returned HTTP headers should include:
      | header               | value                                                       |
      | Content-Type         | <content-type>                                              |
      | Content-Disposition  | attachment; filename="nucleotides_benchmark_metrics.<name>" |
    And the returned body should be a valid <format> document
    And the returned document should contain <n> entries

    Examples:
      | name | format | content-type                   | n | fix                                                |
      | csv  | CSV    | text/csv;charset=UTF-8         | 0 | benchmark_instance/one_partially_completed         |
      | json | JSON   | application/json;charset=UTF-8 | 0 | benchmark_instance/one_partially_completed         |
      | csv  | CSV    | text/csv;charset=UTF-8         | 3 | benchmark_instance/one_completed                   |
      | json | JSON   | text/csv;charset=UTF-8         | 1 | benchmark_instance/one_completed                   |
      | csv  | CSV    | application/json;charset=UTF-8 | 3 | benchmark_instance/one_completed_twice             |
      | json | JSON   | application/json;charset=UTF-8 | 1 | benchmark_instance/one_completed_twice             |
      | csv  | CSV    | text/csv;charset=UTF-8         | 6 | benchmark_instance/two_completed                   |
      | json | JSON   | text/csv;charset=UTF-8         | 1 | benchmark_instance/two_completed                   |
      | csv  | CSV    | text/csv;charset=UTF-8         | 0 | two_benchmark_instances_failed                     |
      | json | JSON   | application/json;charset=UTF-8 | 0 | two_benchmark_instances_failed                     |
      | csv  | CSV    | text/csv;charset=UTF-8         | 2 | benchmark_instances_completed_with_initial_failure |
      | json | JSON   | application/json;charset=UTF-8 | 1 | benchmark_instances_completed_with_initial_failure |



  Scenario: Getting results when some tasks have failed
    Given the database fixtures:
      | fixture                                                         |
      | testing_data/benchmark_instances_completed_with_initial_failure |
    When I get the url "/results/complete?format=json"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | 0/biological_sources/0/file_sets/0/files/0/images/0/versions/0/image_tasks/0/metrics/0/value | 1.0 |
      | 0/biological_sources/0/file_sets/0/files/1/images/0/versions/0/image_tasks/0/metrics/0/value | 1.0 |
