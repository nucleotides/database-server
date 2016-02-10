Feature: Getting benchmarks from the API by their ID

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

  Scenario: Getting a benchmark with no events
    When I get the url "/benchmarks/2f221a18eb86380369570b2ed147d8b4"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id                   | "2f221a18eb86380369570b2ed147d8b4" |
      | complete             | false                              |
      | type                 | something                          |
    And the JSON at "tasks/0" should have the following:
      | type            | "produce"              |
      | status          | "pending_data"         |
      | outputs         | []                     |
      | metrics         | []                     |
      | inputs/0/url    | "s3://reads"           |
      | inputs/0/sha256 | "c1f0f"                |
      | inputs/0/type   | "short_read_fastq"     |
      | image/task      | "default"              |
      | image/name      | "bioboxes/velvet"      |
      | image/sha256    | "digest_1"             |
      | image/type      | "short_read_assembler" |
    And the JSON at "tasks/1" should have the following:
      | type            | "evaluate"                      |
      | status          | "pending_inputs"                |
      | image/task      | "default"                       |
      | image/name      | "bioboxes/quast"                |
      | image/sha256    | "digest_4"                      |
      | image/type      | "reference_assembly_evaluation" |
      | outputs         | []                              |
      | inputs/0/url    | "s3://ref"                      |
      | inputs/0/sha256 | "d421a4"                        |
      | inputs/0/type   | "reference_fasta"               |
      | metrics         | []                              |
