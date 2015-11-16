Feature: Getting and posting benchmarks to the API

  Scenario: Getting a single benchmark from the API
    Given the database scenario with "a single benchmark"
    When I get the url "/benchmarks/show.json"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain the entries:
      | image_name | image_sha256 | image_task | input_url | input_md5 | complete |
      | image      | 123456       | default    | s3://url  | 123456    | false    |

  Scenario: Getting a single benchmark from the API
    Given the database scenario with "a single benchmark"
    When I get the url "/benchmarks/show.json?complete=false"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain the entries:
      | image_name | image_sha256 | image_task | input_url | input_md5 | complete |
      | image      | 123456       | default    | s3://url  | 123456    | false    |

  Scenario: Getting a single benchmark from the API
    Given the database scenario with "a single benchmark"
    When I get the url "/benchmarks/show.json?complete=true"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should not contain any entries
