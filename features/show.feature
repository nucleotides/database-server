Feature: Featching single event records from the database

  Scenario: Sending a GET request to "/events/show.json" with a valid ID
    Given I post to url "/events" with the data:
    """
    {
      "benchmark_id"       : "af0d438",
      "benchmark_type_code": "0000",
      "status_code"        : "0000",
      "event_type_code"    : "0000"
    }
    """
    When I get the url "/events/show.json" with the event id
    Then the returned HTTP status code should be "200"
     And the returned body should be a valid JSON document
     And the returned JSON document should match the key-value pairs:
       | key        | value           |
       | id         | ^\d+$           |
       | created_at | ^\d+T\d+\.\d+Z$ |
     And the returned JSON document should include the key-value pairs:
       | key                 | value   |
       | benchmark_id        | af0d438 |
       | benchmark_type_code | 0000    |
       | status_code         | 0000    |
       | event_type_code     | 0000    |

  Scenario Outline: Sending a GET request to "/events/show.json" with for optional data
    Given I post to url "/events" with the data:
    """
    {
      "benchmark_id"       : "af0d438",
      "benchmark_type_code": "0000",
      "status_code"        : "0000",
      "event_type_code"    : "0000",
      "<field_1>"          : "<value_1>",
      "<field_2>"          : "<value_2>"
    }
    """
    When I get the url "/events/show.json" with the event id
    Then the returned HTTP status code should be "200"
     And the returned body should be a valid JSON document
     And the returned JSON document should match the key-value pairs:
       | key        | value           |
       | id         | ^\d+$           |
       | created_at | ^\d+T\d+\.\d+Z$ |
     And the returned JSON document should include the key-value pairs:
       | key                 | value     |
       | benchmark_id        | af0d438   |
       | benchmark_type_code | 0000      |
       | status_code         | 0000      |
       | event_type_code     | 0000      |
       | <field_1>           | <value_1> |
       | <field_2>           | <value_2> |

    Examples:
      | field_1           | value_1   | field_2           | value_2      |
      | log_file_s3_url   | log_url   | log_file_digest   | log_digest   |
      | event_file_s3_url | event_url | event_file_digest | event_digest |
