Feature: Getting benchmarking tasks by ID

  Scenario: Getting a produce task by ID
    Given the database fixtures:
      | fixture             |
      | metadata            |
      | input_data_source   |
      | input_data_file_set |
      | input_data_file     |
      | image_instance      |
      | benchmarks          |
      | tasks               |
    When I get the url "/tasks/1"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain:
      | key          | value                |
      | id           | 1                    |
      | task_type    | produce              |
      | image_task   | default              |
      | image_name   | bioboxes/velvet      |
      | image_type   | short_read_assembler |
      | image_sha256 | 123abc               |
      | input_url    | s3://url             |
      | input_md5    | abcdef               |
