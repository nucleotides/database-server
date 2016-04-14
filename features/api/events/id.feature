Feature: Getting events from the API

  Background:
    Given a clean database
    And the database fixtures:
      | fixture                 |
      | metadata                |
      | biological_source       |
      | input_data_file_set     |
      | input_data_file         |
      | assembly_image_instance |
      | benchmark_type          |
      | benchmark_data          |
      | tasks                   |


  Scenario: Getting an unknown event
    When I get the url "/events/1000"
    Then the returned HTTP status code should be "404"
    And the returned body should equal "Event not found: 1000"

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
      | metrics        | {}         |

  Scenario: Getting a successful event
    Given I successfully post to "/events" with the data:
      """
      {
         "task":1,
         "success":true,
         "files":[
            {
               "url":"s3://url",
               "sha256":"adef5c",
               "type":"log"
            },
            {
               "url":"s3://url",
               "sha256":"afd456",
               "type":"contig_fasta"
            }
         ],
         "metrics":{
            "ng50":20000,
            "lg50":10
         }
      }
      """
    When I get the url "/events/1"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the JSON should have the following:
      | id             | 1              |
      | task           | 1              |
      | success        | true           |
      | files/0/type   | "log"          |
      | files/0/sha256 | "adef5c"       |
      | files/0/url    | "s3://url"     |
      | files/1/type   | "contig_fasta" |
      | files/1/sha256 | "afd456"       |
      | files/1/url    | "s3://url"     |
      | metrics/ng50   | 20000.0        |
      | metrics/lg50   | 10.0           |
