Feature: Fetching specific records by querying the database

  Scenario: Querying data by the benchmark_id
    Given I post to url "/events" with the records:
      | benchmark_id | benchmark_type_code | status_code | event_type_code |
      | id_1         | 0000                | 0000        | 0000            |
      | id_2         | 0000                | 0000        | 0000            |
    When I get the url "/events/lookup.json?benchmark_id=id_1"
    Then the returned HTTP status code should be "200"
     And the returned body should be a valid JSON document
     And the JSON document should contain "1" entries
     And the JSON document entry "0" should include the key-value pairs
       | key                 | value   |
       | benchmark_id        | id_1    |
