Feature: Getting and posting benchmarks to the API

  Scenario: Getting a single benchmark from the API
    Given the database scenario with "a single benchmark"
    When I get the url "/benchmarks/show.json"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain the entries:
      | image_name | image_sha256 | image_task | input_url | input_md5 | product | evaluation |
      | image      | 123456       | default    | s3://url  | 123456    | false   | false      |

  Scenario: Getting a single benchmark with completed product from the API
    Given the database scenario with "a single benchmark with completed product"
    When I get the url "/benchmarks/show.json"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain the entries:
      | image_name | image_sha256 | image_task | input_url | input_md5 | product | evaluation |
      | image      | 123456       | default    | s3://url  | 123456    | true    | false      |

  Scenario: Getting a single benchmark with completed evaluation from the API
    Given the database scenario with "a single benchmark with completed evaluation"
    When I get the url "/benchmarks/show.json"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain the entries:
      | image_name | image_sha256 | image_task | input_url | input_md5 | product | evaluation |
      | image      | 123456       | default    | s3://url  | 123456    | true    | true       |

  Scenario Outline: Getting benchmarks from the API subselecting using query parameters
    Given the database scenario with "a single benchmark <data>"
    When I get the url "/benchmarks/show.json<params>"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should <state>

    Examples:
      | data                      | params            | state        |
      |                           | ?product=true     | be empty     |
      |                           | ?product=false    | not be empty |
      |                           | ?evaluation=true  | be empty     |
      |                           | ?evaluation=false | not be empty |
      | with completed product    | ?product=true     | not be empty |
      | with completed product    | ?product=false    | be empty     |
      | with completed evaluation | ?product=true     | not be empty |
      | with completed evaluation | ?product=false    | be empty     |
      | with completed evaluation | ?evaluation=true  | not be empty |
      | with completed evaluation | ?evaluation=false | be empty     |
