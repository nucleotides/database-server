Feature: Migrating and loading input data for the database

  Scenario: Migrating and loading the database using POSTGRES_* ENV variables
    Given an empty database without any tables
    And I copy the directory "../../test/data" to "data"
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
      | name          |
      | platform_type |
      | protocol_type |
      | platform_type |
      | run_mode_type |
      | file_type     |
      | metric_type   |
      | source_type   |
    And the table "input_data_source" should have the entries:
      | name             | source_type_id                 |
      | ecoli_k12        | $source_type?name='microbe'    |
      | kansas_farm_soil | $source_type?name='metagenome' |
    And the table "input_data_source_reference_file" should have the entries:
      | input_data_source_id                | file_instance_id              |
      | $input_data_source?name='ecoli_k12' | $file_instance?sha256='eaa53' |
    And the table "input_data_file_set" should have the entries:
      | name                        | input_data_source_id                |
      | jgi_isolate_microbe_2x150_1 | $input_data_source?name='ecoli_k12' |
    And the table "input_data_file" should have the entries:
      | input_data_file_set_id                                  | file_instance_id              |
      | $input_data_file_set?name='jgi_isolate_microbe_2x150_1' | $file_instance?sha256='7673a' |
      | $input_data_file_set?name='jgi_isolate_microbe_2x150_1' | $file_instance?sha256='c1f0f' |

  Scenario: Migrating and loading the database using RDS_* ENV variables
    Given an empty database without any tables
    And I copy the directory "../../test/data" to "data"
    When in bash I run:
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

  Scenario: Loading and then reloading the database with the same data
    Given an empty database without any tables
    And I copy the directory "../../test/data" to "data"
    And in bash I successfully run:
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
