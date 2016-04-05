Feature: Migrating and loading input data for the database

  Scenario: Migrating and loading the database using POSTGRES_* ENV variables
    Given an empty database without any tables
    And I copy the directory "../../tmp/input_data" to "data"
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
    And the table "biological_source" should have the entries:
      | name                              | source_type_id                 |
      | amycolatopsis_sulphurea_dsm_46092 | $source_type?name='microbe'    |
    And the table "biological_source_reference_file" should have the entries:
      | biological_source_id                                        | file_instance_id                                                                         |
      | $biological_source?name='amycolatopsis_sulphurea_dsm_46092' | $file_instance?sha256='d2a60c17386f344a6edc08b5b3b389536c36aae1b8d6fc9394e1c132148288e7' |
    And the table "input_data_file_set" should have the entries:
      | name              | biological_source_id                                        |
      | jgi_microbe_00001 | $biological_source?name='amycolatopsis_sulphurea_dsm_46092' |
    And the table "input_data_file" should have the entries:
      | input_data_file_set_id                        | file_instance_id                                                                         |
      | $input_data_file_set?name='jgi_microbe_00001' | $file_instance?sha256='4376581c14355fcf38cc9fdb962b41b8fe68e2d6637efbfdbe10089ce8019c07' |
      | $input_data_file_set?name='jgi_microbe_00001' | $file_instance?sha256='573722ec83179cfb156f8a613691ee7c7d250770b42b111ae58720a8d22dae97' |
    And the table "image_instance" should have the entries:
      | name                 | sha256                                                           | image_type_id                              |
      | bioboxes/velvet      | 6611675a6d3755515592aa71932bd4ea4c26bccad34fae7a3ec1198ddcccddad | $image_type?name='short_read_assembler'    |
      | bioboxes/ray         | faa7f64683ae2e9d364127a173dadb6a42f9fe90799625944cfcadb27fdd5a29 | $image_type?name='short_read_assembler'    |
    And the table "image_instance_task" should have the entries:
      | task    | image_instance_id                           |
      | default | $image_instance?name='bioboxes/velvet'      |
      | careful | $image_instance?name='bioboxes/velvet'      |
    And the table "benchmark_type" should have the entries:
      | name                                          | product_image_type_id                      |
      | illumina_isolate_reference_assembly           | $image_type?name='short_read_assembler'    |
    And the table "benchmark_data" should have the entries:
      | benchmark_type_id                                                    | input_data_file_set_id                        |
      | $benchmark_type?name='illumina_isolate_reference_assembly'           | $input_data_file_set?name='jgi_microbe_00001' |
    And the table "benchmark_instance" should have the entries:
      | file_instance_id                                                                         | benchmark_type_id                                                    | product_image_instance_id                   |
      | $file_instance?sha256='4376581c14355fcf38cc9fdb962b41b8fe68e2d6637efbfdbe10089ce8019c07' | $benchmark_type?name='illumina_isolate_reference_assembly'           | $image_instance?name='bioboxes/velvet'      |
      | $file_instance?sha256='4376581c14355fcf38cc9fdb962b41b8fe68e2d6637efbfdbe10089ce8019c07' | $benchmark_type?name='illumina_isolate_reference_assembly'           | $image_instance?name='bioboxes/ray'         |
    And the table "task_expanded_fields" should have the entries:
      | external_id                      | task_type | image_name                 | image_task |
      | 2f221a18eb86380369570b2ed147d8b4 | produce   | bioboxes/velvet            | default    |
      | 2f221a18eb86380369570b2ed147d8b4 | evaluate  | bioboxes/quast             | default    |
      | 4f57d0ecf9622a0bd8a6e3f79c71a09d | produce   | bioboxes/velvet            | careful    |
      | 4f57d0ecf9622a0bd8a6e3f79c71a09d | evaluate  | bioboxes/quast             | default    |

  Scenario: Migrating and loading the database when there are no images for a benchmark type
    Given an empty database without any tables
    And I copy the directory "../../test/data" to "data"
    And the file "data/image_instance.yml" with:
      """
      ---
      - image_type: short_read_assembler
        name: bioboxes/velvet
        sha256: digest_1
        tasks:
          - default
      - image_type: reference_assembly_evaluation
        name: bioboxes/quast
        sha256: digest_4
        tasks:
          - default
      """
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
