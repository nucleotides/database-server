Feature: Posting events to the API

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
    And the returned HTTP headers should include:
      | header   | value     |
      | Location | /events/1 |

  Scenario: Posting a successful event
    When I post to "/events" with the data:
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
    Then the returned HTTP status code should be "201"
    And the returned HTTP headers should include:
      | header   | value     |
      | Location | /events/1 |

  Scenario: Posting an event with an unknown metric type
    When I post to "/events" with the data:
      """
      {
         "task":1,
         "success":true,
         "files":[
            {
               "url":"s3://url",
               "sha256":"afd456",
               "type":"contig_fasta"
            }
         ],
         "metrics":{
            "unknown" : 20000
         }
      }
      """
    Then the returned HTTP status code should be "422"
    And the returned body should equal "Unknown metrics in request: unknown"

  Scenario: Posting an event with an unknown file type
    When I post to "/events" with the data:
      """
      {
         "task":1,
         "success":false,
         "files":[
            {
               "url":"s3://url",
               "sha256":"afd456",
               "type":"unknown_file_type"
            }
         ]
      }
      """
    Then the returned HTTP status code should be "422"
    And the returned body should equal "Unknown file types in request: unknown_file_type"

  Scenario: Posting two identical events
    When I post to "/events" with the data:
      """
      {
         "task":1,
         "success":true,
         "files":[
            {
               "url":"s3://url",
               "sha256":"adef5c",
               "type":"log"
            }
         ]
      }
      """
    And I post to "/events" with the data:
      """
      {
         "task":1,
         "success":true,
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
    And the returned HTTP headers should include:
      | header   | value     |
      | Location | /events/2 |
