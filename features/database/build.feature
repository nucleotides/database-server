Feature: Migrating and loading input data for the database

  Scenario: Migrating and loading database with artificial inputs
    Given an empty database without any tables
    And I copy the directory "../../data/testing" to "data"
    When in bash I run:
      """
      docker run \
        --env=POSTGRES_HOST=//localhost:5433 \
        --env=POSTGRES_USER=${POSTGRES_USER} \
        --env=POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
        --env=POSTGRES_NAME=${POSTGRES_NAME} \
        --volume=$(realpath data):/data:ro \
        --net=host \
        nucleotides-api \
        migrate
      """
    Then the stderr excluding logging info should not contain anything
    And the exit status should be 0
    And the following tables should not be empty:
      | name                   |
      | platform_type          |
      | protocol_type          |
      | extraction_method_type |
      | material_type          |
      | run_mode_type          |
      | file_type              |
      | metric_type            |
      | source_type            |
      | image_type             |
    And the table "biological_source" should include the entries:
      | name                   | source_type_id              |
      | source_1               | $source_type?name='microbe' |
      | bad_camel_case_source2 | $source_type?name='microbe' |
    And the table "biological_source_reference_file" should include the entries:
      | biological_source_id                             | file_instance_id                           |
      | $biological_source?name='source_1'               | $file_instance?sha256='reference_1_digest' |
      | $biological_source?name='bad_camel_case_source2' | $file_instance?sha256='reference_2_digest' |
    And the table "input_data_file_set" should contain "2" rows
    And the table "input_data_file_set" should include the entries:
      | name              | biological_source_id                             |
      | data_set_1_data_1 | $biological_source?name='source_1'               |
      | data_set_2_data_1 | $biological_source?name='bad_camel_case_source2' |
    And the table "input_data_file" should contain "3" rows
    And the table "input_data_file" should include the entries:
      | file_instance_id                                                                         |
      | $file_instance?sha256='data_set_1_data_1_digest_1' |
      | $file_instance?sha256='data_set_1_data_1_digest_2' |
      | $file_instance?sha256='data_set_2_data_1_digest_1' |
    And the table "image_instance" should contain "4" rows
    And the table "image_instance" should include the entries:
      | name    | image_type_id                   |
      | image_1 | $image_type?name='image_type_1' |
      | image_2 | $image_type?name='image_type_3' |
      | image_3 | $image_type?name='image_type_2' |
      | image_4 | $image_type?name='image_type_3' |
    And the table "image_version" should contain "5" rows
    And the table "image_version" should include the entries:
       | name | sha256           | image_instance_id              |
       | v1.1 | image_1_digest_1 | $image_instance?name='image_1' |
       | v1.2 | image_1_digest_2 | $image_instance?name='image_1' |
       | v2   | image_2_digest   | $image_instance?name='image_2' |
       | v3   | image_3_digest   | $image_instance?name='image_3' |
       | v4   | image_4_digest   | $image_instance?name='image_4' |
    And the table "image_task" should contain "6" rows
    And the table "image_task" should include the entries:
      | name           | image_version_id                         |
      | image_1_task_1 | $image_version?sha256='image_1_digest_1' |
      | image_1_task_2 | $image_version?sha256='image_1_digest_2' |
      | image_2_task   | $image_version?sha256='image_2_digest'   |
      | image_3_task_1 | $image_version?sha256='image_3_digest'   |
      | image_3_task_2 | $image_version?sha256='image_3_digest'   |
      | image_4_task   | $image_version?sha256='image_4_digest'   |
    And the table "benchmark_type" should contain "3" rows
    And the table "benchmark_type" should include the entries:
       | name        | product_image_type_id                 | evaluation_image_type_id              |
       | benchmark_1 | $image_type?name='image_type_1'       | $image_type?name='image_type_2'       |
       | benchmark_2 | $image_type?name='image_type_3'       | $image_type?name='image_type_2'       |
       | empty       | $image_type?name='non_existing_image' | $image_type?name='non_existing_image' |
    And the table "benchmark_data" should contain "2" rows
    And the table "benchmark_data" should include the entries:
      | benchmark_type_id                  | input_data_file_set_id                        |
      | $benchmark_type?name='benchmark_1' | $input_data_file_set?name='data_set_1_data_1' |
      | $benchmark_type?name='benchmark_2' | $input_data_file_set?name='data_set_2_data_1' |
    And the table "benchmark_instance" should contain "6" rows
    And the table "benchmark_instance" should include the entries:
      | benchmark_type_id                  | file_instance_id                                   | product_image_task_id             |
      | $benchmark_type?name='benchmark_1' | $file_instance?sha256='data_set_1_data_1_digest_1' | $image_task?name='image_1_task_1' |
      | $benchmark_type?name='benchmark_1' | $file_instance?sha256='data_set_1_data_1_digest_1' | $image_task?name='image_1_task_2' |
      | $benchmark_type?name='benchmark_1' | $file_instance?sha256='data_set_1_data_1_digest_2' | $image_task?name='image_1_task_1' |
      | $benchmark_type?name='benchmark_1' | $file_instance?sha256='data_set_1_data_1_digest_2' | $image_task?name='image_1_task_2' |
      | $benchmark_type?name='benchmark_2' | $file_instance?sha256='data_set_2_data_1_digest_1' | $image_task?name='image_2_task'   |
      | $benchmark_type?name='benchmark_2' | $file_instance?sha256='data_set_2_data_1_digest_1' | $image_task?name='image_4_task'   |
    And the table "task" should contain "18" rows


  Scenario: Migrating and loading the database twice using real data and the RDS_* ENV variables
    Given an empty database without any tables
    And I copy the directory "../../tmp/prod_nucleotides_data" to "data"
    And in bash I successfully run:
      """
      docker run \
        --env=RDS_PORT=5433 \
        --env=RDS_USERNAME=${POSTGRES_USER} \
        --env=RDS_PASSWORD=${POSTGRES_PASSWORD} \
        --env=RDS_HOSTNAME=localhost \
        --env=RDS_DB_NAME=${POSTGRES_NAME} \
        --volume=$(realpath data):/data:ro \
        --net=host \
        nucleotides-api \
        migrate
      """
    And in bash I run:
      """
      docker run \
        --env=RDS_PORT=5433 \
        --env=RDS_USERNAME=${POSTGRES_USER} \
        --env=RDS_PASSWORD=${POSTGRES_PASSWORD} \
        --env=RDS_HOSTNAME=localhost \
        --env=RDS_DB_NAME=${POSTGRES_NAME} \
        --volume=$(realpath data):/data:ro \
        --net=host \
        nucleotides-api \
        migrate
      """
    Then the stderr excluding logging info should not contain anything
    And the exit status should be 0
