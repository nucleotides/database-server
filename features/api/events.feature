Feature: Posting and getting events from the API

  Scenario Outline: Completing an event for a task
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
