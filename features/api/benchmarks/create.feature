Feature: Posting benchmarks results to the API

  Scenario Outline: Posting a product benchmark
    Given the database scenario with "a single benchmark"
    When I post the url "/benchmarks/" with:
      | id                               | benchmark_file | log_file | event_type | success |
      | 2f221a18eb86380369570b2ed147d8b4 | s3://url       | s3://url | product    | <state> |
    Then the returned HTTP status code should be "201"
    And the returned body should equal "1"

    Examples:
      | state |
      | true  |
      | false |


  Scenario Outline: Posting an evaluation benchmark
    Given the database scenario with "a single benchmark with completed product"
    When I post the url "/benchmarks/" with:
      | id                               | benchmark_file | log_file | event_type | success |
      | 2f221a18eb86380369570b2ed147d8b4 | s3://url       | s3://url | evaluation | <state> |
    Then the returned HTTP status code should be "201"
    And the returned body should equal "2"

    Examples:
      | state |
      | true  |
      | false |


  Scenario Outline: Posting a product benchmark and requesting the benchmarks
    Given the database scenario with "a single benchmark"
    When I post the url "/benchmarks/" with:
      | id                               | benchmark_file | log_file | event_type | success |
      | 2f221a18eb86380369570b2ed147d8b4 | s3://url       | s3://url | product    | <state> |
    And I get the url "/benchmarks/show.json"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain the entries:
      | image_name | image_sha256 | image_task | input_url | input_md5 | product | evaluation |
      | image      | 123456       | default    | s3://url  | 123456    | <state> | false      |

    Examples:
      | state |
      | true  |
      | false |


  Scenario Outline: Posting an evaluation benchmark and requesting the benchmarks
    Given the database scenario with "a single benchmark with completed product"
    When I post the url "/benchmarks/" with:
      | id                               | benchmark_file | log_file | event_type | success |
      | 2f221a18eb86380369570b2ed147d8b4 | s3://url       | s3://url | evaluation | <state> |
    And I get the url "/benchmarks/show.json"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain the entries:
      | image_name | image_sha256 | image_task | input_url | input_md5 | product | evaluation |
      | image      | 123456       | default    | s3://url  | 123456    | true    | <state>    |

    Examples:
      | state |
      | true  |
      | false |
