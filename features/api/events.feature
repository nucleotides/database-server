Feature: Posting and getting events from the API

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

  Scenario: Posting an unsuccessful event
    When I post to "/events" with the data:
      """
      {
         "task":1,
         "success":false,
         "files":[
            {
               "url":"s3://url",
               "sha256":"adef5c",
               "type":"log"
            }
         ]
      }
      """
    Then the returned HTTP status code should be "201"

  Scenario: Getting an unsuccessful event
    Given I successfully post to "/events" with the data:
      """
      {
         "task":1,
         "success":false,
         "files":[
            {
               "url":"s3://url",
               "sha256":"adef5c",
               "type":"log"
            }
         ]
      }
      """
    When I get the url "/events/1"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id             | 1          |
      | task           | 1          |
      | success        | false      |
      | files/0/type   | "log"      |
      | files/0/sha256 | "adef5c"   |
      | files/0/url    | "s3://url" |
