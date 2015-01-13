Feature: Creating records in event database

  Scenario Outline: Sending an event post request with missing form-data
    When I post to url "/events" with the data:
    """
    <data>
    """
    Then the returned HTTP status code should be "422"
     And the returned body should match "^Missing parameters: .+"

    Examples:
      | data                                                                                |
      | {}                                                                                  |
      | {"benchmark_id" : "af0d438"}                                                        |
      | {"benchmark_id" : "af0d438", "benchmark_type_code": "0000", "status_code" : "0000"} |

  Scenario Outline: Sending an event post request with valid form-data
    When I post to url "/events" with the data:
    """
    { <params>
      "benchmark_id"       : "af0d438",
      "benchmark_type_code": "0000",
      "status_code"        : "0000",
      "event_type_code"    : "0000"
    }
    """
    Then the returned HTTP status code should be "202"
     And the returned body should match "^\d+$"

    Examples:
      | params                                                        |
      |                                                               |
      | "log_file_s3_url" : "url", "log_file_digest" : "ade5...",     |
      | "event_file_s3_url" : "url", "event_file_digest" : "ade5...", |
