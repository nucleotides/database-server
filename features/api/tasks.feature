Feature: Posting and getting tasks from the API

  Scenario: Listing all tasks for an incomplete benchmark
    Given the database scenario with "a single incomplete task"
    When I get the url "/tasks/show.json"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain the entries:
      | image_name      | image_sha256 | image_task | input_url | input_md5 | task_type | image_type           |
      | bioboxes/velvet | 123abc       | default    | s3://url  | abcdef    | produce   | short_read_assembler |

  Scenario Outline: Listing all tasks for a product-completed benchmark
    Given the database scenario with "a single incomplete task"
    When I post to "/tasks/" with the data:
      """
      {
        "id"             : 1,
        "log_file"       : "s3://url",
        "success"        : <state>
        <input_url>
      }
      """
    Then the returned HTTP status code should be "200"

    Examples:
      | state | input_url                       |
      | true  | , "benchmark_file" : "s3://url" |
      | false |                                 |
      | false | , "benchmark_file" : null       |
