Feature: Getting all incomplete tasks from the API

  Background:
    Given a clean database
    And the database fixtures:
      | fixture                 |
      | metadata                |
      | input_data_source       |
      | input_data_file_set     |
      | input_data_file         |
      | assembly_image_instance |
      | benchmarks              |
      | tasks                   |

  Scenario: Listing all tasks
    When I get the url "/tasks/show.json"
    Then the returned HTTP status code should be "200"
    And the JSON should be [1,3,5,7,9,11]

  Scenario: Listing all tasks with an unsuccessful produce event
    Given the database fixtures:
      | fixture                    |
      | unsuccessful_product_event |
    When I get the url "/tasks/show.json"
    Then the returned HTTP status code should be "200"
    And the JSON should be [1,3,5,7,9,11]

  Scenario: Listing all tasks with a successful produce event
    Given the database fixtures:
      | fixture                  |
      | successful_product_event |
    When I get the url "/tasks/show.json"
    Then the returned HTTP status code should be "200"
    And the JSON should be [3,5,7,9,11,2]

  Scenario: Listing all tasks with a unsuccessful followed by successful produce event
    Given the database fixtures:
      | fixture                    |
      | unsuccessful_product_event |
      | successful_product_event   |
    When I get the url "/tasks/show.json"
    Then the returned HTTP status code should be "200"
    And the JSON should be [3,5,7,9,11,2]

  Scenario: Listing all tasks with successful produce and unsuccessful evaluate events
    Given the database fixtures:
      | fixture                     |
      | successful_product_event    |
      | unsuccessful_evaluate_event |
    When I get the url "/tasks/show.json"
    Then the returned HTTP status code should be "200"
    And the JSON should be [3,5,7,9,11,2]

  Scenario: Listing all tasks with successful produce and mixed success evaluate events
    Given the database fixtures:
      | fixture                     |
      | successful_product_event    |
      | unsuccessful_evaluate_event |
      | successful_evaluate_event   |
    When I get the url "/tasks/show.json"
    Then the returned HTTP status code should be "200"
    And the JSON should be [3,5,7,9,11]
