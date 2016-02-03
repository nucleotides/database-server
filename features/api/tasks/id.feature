Feature: Getting benchmarking tasks by ID

  Background:
    Given a clean database
    And the database fixtures:
      | fixture             |
      | metadata            |
      | input_data_source   |
      | input_data_file_set |
      | input_data_file     |
      | image_instance      |
      | benchmarks          |
      | tasks               |

  Scenario: Getting a incomplete produce task by ID
    When I get the url "/tasks/1"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id             | 1                                  |
      | benchmark      | "453e406dcee4d18174d4ff623f52dcd8" |
      | task_type      | "produce"                          |
      | image_task     | "default"                          |
      | image_name     | "bioboxes/ray"                     |
      | image_type     | "short_read_assembler"             |
      | image_sha256   | "digest_2"                         |
      | files/0/url    | "s3://reads"                       |
      | files/0/sha256 | "c1f0f"                            |
      | files/0/type   | "short_read_fastq"                 |
    And the JSON response should not have "benchmark_instance_id"

  Scenario: Getting an incomplete evaluate task by ID
    When I get the url "/tasks/2"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id             | 2                                  |
      | benchmark      | "453e406dcee4d18174d4ff623f52dcd8" |
      | task_type      | "evaluate"                         |
      | image_task     | "default"                          |
      | image_name     | "bioboxes/quast"                   |
      | image_type     | "reference_assembly_evaluation"    |
      | image_sha256   | "digest_4"                         |
      | files/0/url    | "s3://ref"                         |
      | files/0/sha256 | "d421a4"                           |
      | files/0/type   | "reference_fasta"                  |
    And the JSON response should not have "benchmark_instance_id"
