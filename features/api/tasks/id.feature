Feature: Getting tasks from the API by ID

  Scenario: Getting a produce task by ID
    Given the database scenario with "a single incomplete task"
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

  Scenario: Getting an evaluate task without inputs by ID
    Given the database scenario with "a single incomplete task"
    When I get the url "/tasks/2"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain:
       | key          | value                |
       | id           | 2                    |
       | task_type    | evaluate             |
       | image_task   | default              |
       | image_name   | bioboxes/quast       |
       | image_type   | assembly_evaluation  |
       | image_sha256 | 123abc               |
       | input_url    |                      |
       | input_md5    |                      |

  Scenario: Getting an evaluate task with failed produce inputs
    Given the database scenario with "a single incomplete task"
    And I successfully post to "/events" with the data:
      """
      { "task"          : 1,
        "log_file_url"  : "log_url",
        "success"       : false }
      """
    When I get the url "/tasks/2"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain:
       | key          | value                |
       | id           | 2                    |
       | task_type    | evaluate             |
       | image_task   | default              |
       | image_name   | bioboxes/quast       |
       | image_type   | assembly_evaluation  |
       | image_sha256 | 123abc               |
       | input_url    |                      |
       | input_md5    |                      |


  Scenario: Getting an evaluate task with successful produce inputs
    Given the database scenario with "a single incomplete task"
    And I successfully post to "/events" with the data:
      """
      { "task"          : 1,
        "log_file_url"  : "log_url",
        "file_url"      : "product_url",
        "file_md5"      : "123",
        "success"       : true }
      """
    When I get the url "/tasks/2"
    Then the returned HTTP status code should be "200"
    And the returned body should be a valid JSON document
    And the returned JSON should contain:
       | key          | value                |
       | id           | 2                    |
       | task_type    | evaluate             |
       | image_task   | default              |
       | image_name   | bioboxes/quast       |
       | image_type   | assembly_evaluation  |
       | image_sha256 | 123abc               |
       | input_url    | product_url          |
       | input_md5    | 123                  |
