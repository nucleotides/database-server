Feature: Getting benchmarks from the API by their ID

  Scenario: Getting an incomplete benchmark by ID
    Given the database scenario with "a single incomplete task"
    When I get the url "/benchmarks/2f221a18eb86380369570b2ed147d8b4"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain:
      | key          | value    |
      | image_name   | image    |
      | image_sha256 | 123456   |
      | image_task   | default  |
      | input_md5    | 123456   |
      | input_url    | s3://url |
      | product      | false    |
      | product_url  |          |
      | evaluation   | false    |
      | metrics      | {}       |

  Scenario: Getting a product-complete benchmark by ID
    Given the database scenario with "a single benchmark with completed product"
    When I get the url "/benchmarks/2f221a18eb86380369570b2ed147d8b4"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain:
      | key          | value    |
      | image_name   | image    |
      | image_sha256 | 123456   |
      | image_task   | default  |
      | input_md5    | 123456   |
      | input_url    | s3://url |
      | product      | true     |
      | product_url  | s3://url |
      | evaluation   | false    |
      | metrics      | {}       |

  Scenario: Getting a evaluation-complete benchmark by ID
    Given the database scenario with "a single benchmark with completed evaluation"
    When I get the url "/benchmarks/2f221a18eb86380369570b2ed147d8b4"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain:
      | key          | value    |
      | image_name   | image    |
      | image_sha256 | 123456   |
      | image_task   | default  |
      | input_md5    | 123456   |
      | input_url    | s3://url |
      | product      | true     |
      | product_url  | s3://url |
      | evaluation   | true     |
      | metrics.ng50 | 20000.0  |
      | metrics.lg50 | 10.0     |
