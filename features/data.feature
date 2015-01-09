Feature: Sending and fetching data from the event API server

  Scenario: Sending an event post request with missing form-data
    When I post to url "/events" with the data:
    """
    {}
    """
    Then the returned HTTP status code should be "422"

  Scenario: Sending an event post request with valid form-data
    When I post to url "/events" with the data:
    """
    {
      "benchmark_id"       : "af0d438",
      "benchmark_type_code": "0000",
      "status_code"        : "0000",
      "event_type_code"    : "0000"
    }
    """
    Then the returned HTTP status code should be "202"
