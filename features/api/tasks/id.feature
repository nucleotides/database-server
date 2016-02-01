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
