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
    When I post to "/benchmarks/" with the data:
      """
      {
        "id"             : "2f221a18eb86380369570b2ed147d8b4",
        "log_file"       : "s3://url",
        "event_type"     : "product",
        "success"        : <state>
        <input_url>
      }
      """
    And I get the url "/benchmarks/2f221a18eb86380369570b2ed147d8b4"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain:
      | key          | value    |
      | image_name   | image    |
      | image_sha256 | 123456   |
      | image_task   | default  |
      | input_md5    | 123456   |
      | input_url    | s3://url |
      | product      | <state>  |
      | product_url  | <url>    |
      | evaluation   | false    |
      | metrics      | {}       |

    Examples:
      | state | input_url                       | url      |
      | false |                                 |          |
      | true  | , "benchmark_file" : "s3://url" | s3://url |
      | false | , "benchmark_file" : null       |          |


  Scenario Outline: Posting an evaluation benchmark and requesting the benchmarks
    Given the database scenario with "a single benchmark with completed product"
    When I post to "/benchmarks/" with the data:
      """
      {
        "id"             : "2f221a18eb86380369570b2ed147d8b4",
        "log_file"       : "s3://url",
        "event_type"     : "evaluation",
        "success"        : <state>
        <input_metrics>
      }
      """
    And I get the url "/benchmarks/2f221a18eb86380369570b2ed147d8b4"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain:
      | key          | value     |
      | image_name   | image     |
      | image_sha256 | 123456    |
      | image_task   | default   |
      | input_md5    | 123456    |
      | input_url    | s3://url  |
      | product      | true      |
      | product_url  | s3://url  |
      | evaluation   | <state>   |
      | metrics      | <metrics> |

    Examples:
      | input_metrics                               | metrics                       | state |
      |                                             | {}                            | false |
      | , "metrics" : {"ng50": 20000, "lg50" : 10 } | {"ng50": 20000, "lg50" : 10 } | false |
