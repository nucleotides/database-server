Feature: Getting benchmarking tasks by ID

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


  Scenario: Getting an unknown task
    When I get the url "/tasks/1000"
    Then the returned HTTP status code should be "404"
    And the returned body should equal "Task not found: 1000"


  Scenario: Getting an incomplete produce task by ID
    When I get the url "/tasks/1"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id              | 1                                  |
      | complete        | false                              |
      | success         | false                              |
      | benchmark       | "2f221a18eb86380369570b2ed147d8b4" |
      | type            | "produce"                          |
      | image/task      | "default"                          |
      | image/name      | "bioboxes/velvet"                  |
      | image/type      | "short_read_assembler"             |
      | image/sha256    | "digest_1"                         |
      | image/version   | "ver_1"                            |
      | inputs/0/url    | "s3://reads"                       |
      | inputs/0/sha256 | "7673a"                            |
      | inputs/0/type   | "short_read_fastq"                 |
    And the JSON response should not have "benchmark_instance_id"


  Scenario: Getting a complete produce task by ID
    Given the database fixtures:
      | fixture                  |
      | successful_product_event |
    When I get the url "/tasks/1"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON response should not have "benchmark_instance_id"
    And the JSON should have the following:
      | id                      | 1                                  |
      | complete                | true                               |
      | success                 | true                               |
      | benchmark               | "2f221a18eb86380369570b2ed147d8b4" |
      | type                    | "produce"                          |
      | image/task              | "default"                          |
      | image/name              | "bioboxes/velvet"                  |
      | image/type              | "short_read_assembler"             |
      | image/sha256            | "digest_1"                         |
      | inputs/0/url            | "s3://reads"                       |
      | inputs/0/sha256         | "7673a"                            |
      | inputs/0/type           | "short_read_fastq"                 |
      | events/0/id             | 1                                  |
      | events/0/success        | true                               |
      | events/0/files/0/type   | "container_runtime_metrics"        |
      | events/0/files/0/sha256 | "12def"                            |
      | events/0/files/0/url    | "s3://metrics"                     |
      | events/0/files/1/type   | "container_log"                    |
      | events/0/files/1/sha256 | "66b8d"                            |
      | events/0/files/1/url    | "s3://log_file"                    |
      | events/0/files/2/type   | "contig_fasta"                     |
      | events/0/files/2/sha256 | "f7455"                            |
      | events/0/files/2/url    | "s3://contigs"                     |
    And the JSON response should have "events/0/created_at"


  Scenario: Getting failed produce task
    Given the database fixtures:
      | fixture                    |
      | unsuccessful_product_event |
    When I get the url "/tasks/1"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | complete            | true  |
      | success             | false |
      | events/0/id         | 1     |
      | events/0/success    | false |


  Scenario: Getting an incomplete evaluate task by ID
    When I get the url "/tasks/2"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id              | 2                                  |
      | complete        | false                              |
      | success         | false                              |
      | benchmark       | "2f221a18eb86380369570b2ed147d8b4" |
      | type            | "evaluate"                         |
      | image/task      | "default"                          |
      | image/name      | "bioboxes/quast"                   |
      | image/type      | "reference_assembly_evaluation"    |
      | image/sha256    | "digest_3"                         |
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
      | success         | false                              |
      | benchmark       | "2f221a18eb86380369570b2ed147d8b4" |
      | type            | "evaluate"                         |
      | image/task      | "default"                          |
      | image/name      | "bioboxes/quast"                   |
      | image/type      | "reference_assembly_evaluation"    |
      | image/sha256    | "digest_3"                         |
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
      | success         | false                              |
      | benchmark       | "2f221a18eb86380369570b2ed147d8b4" |
      | type            | "evaluate"                         |
      | image/task      | "default"                          |
      | image/name      | "bioboxes/quast"                   |
      | image/type      | "reference_assembly_evaluation"    |
      | image/sha256    | "digest_3"                         |
      | inputs/0/url    | "s3://ref"                         |
      | inputs/0/sha256 | "d421a4"                           |
      | inputs/0/type   | "reference_fasta"                  |
      | inputs/1/url    | "s3://contigs"                     |
      | inputs/1/sha256 | "f7455"                            |
      | inputs/1/type   | "contig_fasta"                     |
    And the JSON response should not have "benchmark_instance_id"
    And the JSON response should not have "inputs/2"


  Scenario: Getting an evaluate task by ID with two successful product events
    Given the database fixtures:
      | fixture                         |
      | successful_product_event        |
      | second_successful_product_event |
    When I get the url "/tasks/2"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id              | 2                                  |
      | complete        | false                              |
      | success         | false                              |
      | benchmark       | "2f221a18eb86380369570b2ed147d8b4" |
      | type            | "evaluate"                         |
      | image/task      | "default"                          |
      | image/name      | "bioboxes/quast"                   |
      | image/type      | "reference_assembly_evaluation"    |
      | image/sha256    | "digest_3"                         |
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
      | complete                | true            |
      | success                 | true            |
      | events/0/success        | true            |
      | events/0/files/0/type   | "container_log" |
      | events/0/files/0/sha256 | "f6b8e"         |
      | events/0/files/0/url    | "s3://log_file" |
    And the JSON response should have "events/0/created_at"


  Scenario: Getting an evaluate task with a successful product and a failed evaluate event
    Given the database fixtures:
      | fixture                     |
      | successful_product_event    |
      | unsuccessful_evaluate_event |
    When I get the url "/tasks/2"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | complete                | true            |
      | success                 | false           |
      | events/0/success        | false           |
    And the JSON response should have "events/0/created_at"
