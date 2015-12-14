Feature: Posting and getting events from the API

  Scenario Outline: Completing an event for a produce task
    Given the database scenario with "a single incomplete task"
    When I post to "/events" with the data:
      """
      { "task"          : 1,
        "log_file_url"  : "s3://url",
        "success"       : <state>
        <file> }
      """
    Then the returned HTTP status code should be "201"

    Examples:
      | state | file                                          |
      | true  | , "file_url" : "s3://url", "file_md5" : "123" |
      | false |                                               |
      | false | , "file_url" : null                           |

  Scenario: Completing an event for a evaluate task
    Given the database scenario with "a single incomplete task"
    When I post to "/events" with the data:
      """
      { "task"           : 2,
        "log_file_url"   : "s3://url",
        "file_url"       : "s3://url",
        "file_md5"       : "123",
        "success"        : true,
        "metrics[ng50]"  : 20000,
        "metrics[lg50]"  : 10 }
      """
    Then the returned HTTP status code should be "201"

  Scenario: Getting a product event
    Given the database scenario with "a single incomplete task"
    And I successfully post to "/events" with the data:
      """
      { "task"          : 1,
        "log_file_url"  : "log_url",
        "file_url"      : "product_url",
        "file_md5"      : "123",
        "success"       : true }
      """
    When I get the url "/events/1"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain:
      | key          | value       |
      | id           | 1           |
      | task_id      | 1           |
      | log_file_url | log_url     |
      | file_url     | product_url |
      | file_md5     | 123         |
      | success      | true        |


  Scenario: Getting an evaluate event
    Given the database scenario with "a single incomplete task"
    And I successfully post to "/events" with the data:
      """
      { "task"           : 2,
        "log_file_url"   : "s3://url",
        "file_url"       : "s3://url",
        "file_md5"       : "123",
        "success"        : true,
        "metrics[ng50]"  : 20000,
        "metrics[lg50]"  : 10 }
      """
    When I get the url "/events/1"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain:
       | key          | value    |
       | id           | 1        |
       | task_id      | 2        |
       | log_file_url | s3://url |
       | file_url     | s3://url |
       | file_md5     | 123      |
       | success      | true     |
       | metrics.ng50 | 20000.0  |
       | metrics.lg50 | 10.0     |
