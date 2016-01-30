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
      | image_type    |
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
    And the table "image_instance" should have the entries:
      | name                 | sha256   | image_type_id                              |
      | bioboxes/velvet      | digest_1 | $image_type?name='short_read_assembler'    |
      | bioboxes/ray         | digest_2 | $image_type?name='short_read_assembler'    |
      | bioboxes/my-filterer | digest_3 | $image_type?name='short_read_preprocessor' |
    And the table "image_instance_task" should have the entries:
      | task    | image_instance_id                           |
      | default | $image_instance?name='bioboxes/velvet'      |
      | careful | $image_instance?name='bioboxes/velvet'      |
      | default | $image_instance?name='bioboxes/my-filterer' |
    And the table "benchmark_type" should have the entries:
      | name                                          | product_image_type_id                      |
      | illumina_isolate_reference_assembly           | $image_type?name='short_read_assembler'    |
      | short_read_preprocessing_reference_evaluation | $image_type?name='short_read_preprocessor' |
    And the table "benchmark_data" should have the entries:
      | benchmark_type_id                                                    | input_data_file_set_id                                  |
      | $benchmark_type?name='illumina_isolate_reference_assembly'           | $input_data_file_set?name='jgi_isolate_microbe_2x150_1' |
      | $benchmark_type?name='short_read_preprocessing_reference_evaluation' | $input_data_file_set?name='jgi_isolate_microbe_2x150_1' |
    And the table "benchmark_instance" should have the entries:
      | file_instance_id              | benchmark_type_id                                                    | product_image_instance_id                   |
      | $file_instance?sha256='7673a' | $benchmark_type?name='illumina_isolate_reference_assembly'           | $image_instance?name='bioboxes/velvet'      |
      | $file_instance?sha256='c1f0f' | $benchmark_type?name='illumina_isolate_reference_assembly'           | $image_instance?name='bioboxes/velvet'      |
      | $file_instance?sha256='7673a' | $benchmark_type?name='illumina_isolate_reference_assembly'           | $image_instance?name='bioboxes/ray'         |
      | $file_instance?sha256='c1f0f' | $benchmark_type?name='illumina_isolate_reference_assembly'           | $image_instance?name='bioboxes/ray'         |
      | $file_instance?sha256='7673a' | $benchmark_type?name='short_read_preprocessing_reference_evaluation' | $image_instance?name='bioboxes/my-filterer' |
      | $file_instance?sha256='c1f0f' | $benchmark_type?name='short_read_preprocessing_reference_evaluation' | $image_instance?name='bioboxes/my-filterer' |
    And the table "task_expanded_fields" should have the entries:
      | external_id                      | task_type | image_name                 | image_task |
      | 0eafe866d98c59ca39715e936cfa401e | produce   | bioboxes/my-filterer       | default    |
      | 0eafe866d98c59ca39715e936cfa401e | evaluate  | bioboxes/velvet-then-quast | default    |
      | 2f221a18eb86380369570b2ed147d8b4 | produce   | bioboxes/velvet            | default    |
      | 2f221a18eb86380369570b2ed147d8b4 | evaluate  | bioboxes/quast             | default    |
      | 4f57d0ecf9622a0bd8a6e3f79c71a09d | produce   | bioboxes/velvet            | careful    |
      | 4f57d0ecf9622a0bd8a6e3f79c71a09d | evaluate  | bioboxes/quast             | default    |
    And the table "task_expanded_fields" should not have the entries:
      | external_id                      | task_type | image_name                 | image_task |
      | 0eafe866d98c59ca39715e936cfa401e | evaluate  | bioboxes/quast             | default    |
      | 2f221a18eb86380369570b2ed147d8b4 | evaluate  | bioboxes/velvet-then-quast | default    |


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
