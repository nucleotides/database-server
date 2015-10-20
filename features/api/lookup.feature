Feature: Fetching specific records by querying the database

  Scenario Outline: Querying data using different parameters
    Given the database contains the records:
      | benchmark_id | benchmark_type_code | status_code | event_type_code |
      | query_id_1   | 0000                | 0000        | 0000            |
      | query_id_2   | 0001                | 0000        | 0000            |
      | query_id_3   | 0000                | 0001        | 0000            |
      | query_id_4   | 0000                | 0000        | 0001            |
    When I get the url "/events/lookup.json?<query>"
    Then the returned HTTP status code should be "200"
     And the returned body should be a valid JSON document
     And the JSON document should include include the events:
       | benchmark_id   |
       | query_id_<inc> |
     And the JSON document should not include include the events:
       | benchmark_id     |
       | query_id_<exc_1> |
       | query_id_<exc_2> |
       | query_id_<exc_3> |

    Examples:
      | query                    | inc | exc_1 | exc_2 | exc_3 |
      | benchmark_id=query_id_1  | 1   | 2     | 3     | 4     |
      | benchmark_type_code=0001 | 2   | 3     | 4     | 1     |
      | status_code=0001         | 3   | 4     | 1     | 2     |
      | event_type_code=0001     | 4   | 1     | 2     | 3     |

  Scenario: Querying data using multiple parameters
    Given the database contains the records:
      | benchmark_id | benchmark_type_code | status_code | event_type_code |
      | query_id_1   | 0000                | 0000        | 0000            |
      | query_id_2   | 0001                | 0000        | 0000            |
    When I get the url "/events/lookup.json?benchmark_type_code=0000&status_code=0000"
    Then the returned HTTP status code should be "200"
     And the returned body should be a valid JSON document
     And the JSON document should include include the events:
       | benchmark_id   |
       | query_id_1|
     And the JSON document should not include include the events:
       | benchmark_id     |
       | query_id_2       |


  Scenario: Querying and paging records using max_id
    Given I post to url "/events/update" with the records:
      | benchmark_id | benchmark_type_code | status_code | event_type_code |
      | page_id_1    | 0000                | 0000        | 0000            |
      | page_id_2    | 0001                | 0000        | 0000            |
      And I save the last event id
      And I post to url "/events" with the records:
      | benchmark_id | benchmark_type_code | status_code | event_type_code |
      | page_id_3    | 0000                | 0001        | 0000            |
    When I lookup the records using the max_id
    Then the returned HTTP status code should be "200"
     And the returned body should be a valid JSON document
     And the JSON document should include include the events:
       | benchmark_id |
       | page_id_1    |
       | page_id_2    |
     And the JSON document should not include include the events:
       | benchmark_id |
       | page_id_3    |
