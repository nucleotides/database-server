Feature: Getting benchmarking tasks by ID

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

  Scenario: Getting an incomplete produce task by ID
    When I get the url "/tasks/1"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id              | 1                                  |
      | complete        | false                              |
      | benchmark       | "453e406dcee4d18174d4ff623f52dcd8" |
      | type            | "produce"                          |
      | image/task      | "default"                          |
      | image/name      | "bioboxes/ray"                     |
      | image/type      | "short_read_assembler"             |
      | image/sha256    | "digest_2"                         |
      | inputs/0/url    | "s3://reads"                       |
      | inputs/0/sha256 | "c1f0f"                            |
      | inputs/0/type   | "short_read_fastq"                 |
    And the JSON response should not have "benchmark_instance_id"

  Scenario: Getting a complete produce task by ID
    Given the database fixtures:
      | fixture                  |
      | successful_product_event |
    When I get the url "/tasks/1"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id              | 1                                  |
      | complete        | true                               |
      | benchmark       | "453e406dcee4d18174d4ff623f52dcd8" |
      | type            | "produce"                          |
      | image/task      | "default"                          |
      | image/name      | "bioboxes/ray"                     |
      | image/type      | "short_read_assembler"             |
      | image/sha256    | "digest_2"                         |
      | inputs/0/url    | "s3://reads"                       |
      | inputs/0/sha256 | "c1f0f"                            |
      | inputs/0/type   | "short_read_fastq"                 |
    And the JSON response should not have "benchmark_instance_id"

  Scenario: Getting a complete produce task by ID
    Given the database fixtures:
      | fixture                    |
      | unsuccessful_product_event |
    When I get the url "/tasks/1"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | complete | false |

  Scenario: Getting an incomplete evaluate task by ID
    When I get the url "/tasks/2"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id              | 2                                  |
      | complete        | false                              |
      | benchmark       | "453e406dcee4d18174d4ff623f52dcd8" |
      | type            | "evaluate"                         |
      | image/task      | "default"                          |
      | image/name      | "bioboxes/quast"                   |
      | image/type      | "reference_assembly_evaluation"    |
      | image/sha256    | "digest_4"                         |
      | inputs/0/url    | "s3://ref"                         |
      | inputs/0/sha256 | "d421a4"                           |
      | inputs/0/type   | "reference_fasta"                  |
    And the JSON response should not have "benchmark_instance_id"

  Scenario: Getting an evaluate task with an unsuccessful product event by ID
    Given the database fixtures:
      | fixture                    |
      | unsuccessful_product_event |
    When I get the url "/tasks/2"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id              | 2                                  |
      | complete        | false                              |
      | benchmark       | "453e406dcee4d18174d4ff623f52dcd8" |
      | type            | "evaluate"                         |
      | image/task      | "default"                          |
      | image/name      | "bioboxes/quast"                   |
      | image/type      | "reference_assembly_evaluation"    |
      | image/sha256    | "digest_4"                         |
      | inputs/0/url    | "s3://ref"                         |
      | inputs/0/sha256 | "d421a4"                           |
      | inputs/0/type   | "reference_fasta"                  |
    And the JSON response should not have "benchmark_instance_id"
    And the JSON response should not have "inputs/1"

  Scenario: Getting an evaluate task with a successful product event by ID
    Given the database fixtures:
      | fixture                  |
      | successful_product_event |
    When I get the url "/tasks/2"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id              | 2                                  |
      | complete        | false                              |
      | benchmark       | "453e406dcee4d18174d4ff623f52dcd8" |
      | type            | "evaluate"                         |
      | image/task      | "default"                          |
      | image/name      | "bioboxes/quast"                   |
      | image/type      | "reference_assembly_evaluation"    |
      | image/sha256    | "digest_4"                         |
      | inputs/0/url    | "s3://ref"                         |
      | inputs/0/sha256 | "d421a4"                           |
      | inputs/0/type   | "reference_fasta"                  |
      | inputs/1/url    | "s3://contigs"                     |
      | inputs/1/sha256 | "f7455"                            |
      | inputs/1/type   | "contig_fasta"                     |
    And the JSON response should not have "benchmark_instance_id"
    And the JSON response should not have "inputs/2"

  Scenario: Getting an evaluate task with a successful product and evaluate event
    Given the database fixtures:
      | fixture                   |
      | successful_product_event  |
      | successful_evaluate_event |
    When I get the url "/tasks/2"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | complete | true |
