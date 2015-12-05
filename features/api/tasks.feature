Feature: Posting and getting tasks from the API

  Scenario: Listing incomplete tasks with an incomplete benchmark
    Given the database scenario with "a single incomplete task"
    When I get the url "/tasks/show.json"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain the entries:
      | image_name      | image_sha256 | image_task | input_url | input_md5 | type    |
      | bioboxes/velvet | 123abc       | default    | s3://url  | abcdef    | produce |
