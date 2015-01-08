Feature: Sending and fetching data from the event API server

  Scenario: Sending an event post request with missing form-data
    When I post to url "/events" with the data:
    """
    {}
    """
    Then the returned HTTP status code should be "422"
