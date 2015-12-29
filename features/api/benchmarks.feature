Feature: Getting benchmarks from the API by their ID

  Scenario: Getting an incomplete benchmark by ID
    Given the database scenario with "a single incomplete task"
    When I get the url "/benchmarks/2f221a18eb86380369570b2ed147d8b4"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain:
       | key          | value           |
       | image.name   | bioboxes/velvet |
       | image.sha256 | 123abc          |
       | image.task   | default         |
       | product      |                 |
       | evaluate     | []              |
       | metrics      | {}              |
