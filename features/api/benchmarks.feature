Feature: Getting benchmarks from the API by their ID

  Background:
    Given a clean database
    And the database fixtures:
      | fixture                 |
      | metadata                |
      | biological_source       |
      | biological_source_files |
      | input_data_file_set     |
      | input_data_file         |
      | assembly_image_instance |
      | benchmark_type          |
      | benchmark_data          |
      | tasks                   |


  Scenario: Getting an unknown benchmark
    When I get the url "/benchmarks/unknown"
    Then the returned HTTP status code should be "404"
    And the returned body should equal "Benchmark not found: unknown"

  Scenario: Getting a benchmark with no completed tasks
    When I get the url "/benchmarks/2f221a18eb86380369570b2ed147d8b4"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id       | "2f221a18eb86380369570b2ed147d8b4"    |
      | complete | false                                 |
      | type     | "illumina_isolate_reference_assembly" |
    And the JSON should not have "task_id"
    And the JSON at "tasks/0" should have the following:
      | type            | "produce"              |
      | complete        | false                  |
      | inputs/0/url    | "s3://reads"           |
      | inputs/0/sha256 | "7673a"                |
      | inputs/0/type   | "short_read_fastq"     |
      | image/task      | "default"              |
      | image/name      | "bioboxes/velvet"      |
      | image/sha256    | "digest_1"             |
      | image/type      | "short_read_assembler" |
    And the JSON at "tasks/1" should have the following:
      | type            | "evaluate"                      |
      | complete        | false                           |
      | image/task      | "default"                       |
      | image/name      | "bioboxes/quast"                |
      | image/sha256    | "digest_4"                      |
      | image/type      | "reference_assembly_evaluation" |
      | inputs/0/url    | "s3://ref"                      |
      | inputs/0/sha256 | "d421a4"                        |
      | inputs/0/type   | "reference_fasta"               |

  Scenario: Getting a benchmark with a completed produce task
    Given the database fixtures:
      | fixture                  |
      | successful_product_event |
    When I get the url "/benchmarks/453e406dcee4d18174d4ff623f52dcd8"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id       | "453e406dcee4d18174d4ff623f52dcd8"    |
      | complete | false                                 |
      | type     | "illumina_isolate_reference_assembly" |
    And the JSON should not have "task_id"
    And the JSON at "tasks/0" should have the following:
      | id              | 1                                  |
      | complete        | true                               |
      | type            | "produce"                          |
      | image/task      | "default"                          |
      | image/name      | "bioboxes/ray"                     |
      | image/type      | "short_read_assembler"             |
      | image/sha256    | "digest_2"                         |
      | inputs/0/url    | "s3://reads"                       |
      | inputs/0/sha256 | "c1f0f"                            |
      | inputs/0/type   | "short_read_fastq"                 |
    And the JSON response should not have "task/0/inputs/1"
    And the JSON at "tasks/1" should have the following:
      | id              | 2                                  |
      | complete        | false                              |
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
    And the JSON response should not have "task/1/inputs/2"

  Scenario: Getting a benchmark with all completed tasks
    Given the database fixtures:
      | fixture                  |
      | successful_product_event |
      | successful_evaluate_event |
    When I get the url "/benchmarks/453e406dcee4d18174d4ff623f52dcd8"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id       | "453e406dcee4d18174d4ff623f52dcd8"    |
      | complete | true                                  |
      | type     | "illumina_isolate_reference_assembly" |
    And the JSON should not have "task_id"
    And the JSON at "tasks/0" should have the following:
      | id              | 1                                  |
      | complete        | true                               |
      | type            | "produce"                          |
      | image/task      | "default"                          |
      | image/name      | "bioboxes/ray"                     |
      | image/type      | "short_read_assembler"             |
      | image/sha256    | "digest_2"                         |
      | inputs/0/url    | "s3://reads"                       |
      | inputs/0/sha256 | "c1f0f"                            |
      | inputs/0/type   | "short_read_fastq"                 |
    And the JSON response should not have "task/0/inputs/1"
    And the JSON at "tasks/1" should have the following:
      | id              | 2                                  |
      | complete        | true                               |
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
    And the JSON response should not have "task/1/inputs/2"
