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
      | name                              | source_type_id                 |
      | amycolatopsis_sulphurea_dsm_46092 | $source_type?name='microbe'    |
    And the table "biological_source_reference_file" should include the entries:
      | biological_source_id                                        | file_instance_id                                                                         |
      | $biological_source?name='amycolatopsis_sulphurea_dsm_46092' | $file_instance?sha256='d2a60c17386f344a6edc08b5b3b389536c36aae1b8d6fc9394e1c132148288e7' |
    And the table "input_data_file_set" should contain "1" rows
    And the table "input_data_file_set" should include the entries:
      | name               | biological_source_id                                        |
      | regular_fragment_1 | $biological_source?name='amycolatopsis_sulphurea_dsm_46092' |
    And the table "input_data_file" should contain "5" rows
    And the table "input_data_file" should include the entries:
      | file_instance_id                                                                         |
      | $file_instance?sha256='4376581c14355fcf38cc9fdb962b41b8fe68e2d6637efbfdbe10089ce8019c07' |
      | $file_instance?sha256='573722ec83179cfb156f8a613691ee7c7d250770b42b111ae58720a8d22dae97' |
    And the table "image_instance" should contain "3" rows
    And the table "image_instance" should include the entries:
      | name                  | image_type_id                                    |
      | bioboxes/velvet       | $image_type?name='short_read_assembler'          |
      | bioboxes/ray          | $image_type?name='short_read_assembler'          |
      | bioboxes/quast        | $image_type?name='reference_assembly_evaluation' |
    And the table "image_version" should contain "3" rows
    And the table "image_version" should include the entries:
      | name   | sha256                                                           | image_instance_id                      |
      | 1.2.0  | 6611675a6d3755515592aa71932bd4ea4c26bccad34fae7a3ec1198ddcccddad | $image_instance?name='bioboxes/velvet' |
      | 2.3.0  | faa7f64683ae2e9d364127a173dadb6a42f9fe90799625944cfcadb27fdd5a29 | $image_instance?name='bioboxes/ray'    |
      | 4.2    | 5af634ee3f1bc3f80a749ce768883a20f793e1791f8f404a316d7d7012423cb9 | $image_instance?name='bioboxes/quast'  |
    And the table "image_task" should contain "4" rows
    And the table "image_task" should include the entries:
      | name    | image_version_id                                                                         |
      | default | $image_version?sha256='6611675a6d3755515592aa71932bd4ea4c26bccad34fae7a3ec1198ddcccddad' |
      | default | $image_version?sha256='faa7f64683ae2e9d364127a173dadb6a42f9fe90799625944cfcadb27fdd5a29' |
      | default | $image_version?sha256='5af634ee3f1bc3f80a749ce768883a20f793e1791f8f404a316d7d7012423cb9' |
    And the table "benchmark_type" should contain "1" rows
    And the table "benchmark_type" should include the entries:
      | name                                          | product_image_type_id                      |
      | illumina_isolate_reference_assembly           | $image_type?name='short_read_assembler'    |
    And the table "benchmark_data" should contain "1" rows
    And the table "benchmark_data" should include the entries:
      | benchmark_type_id                                                    |
      | $benchmark_type?name='illumina_isolate_reference_assembly'           |
    And the table "benchmark_instance" should contain "15" rows
    And the table "benchmark_instance" should include the entries:
      | file_instance_id                                                                         | benchmark_type_id                                                    |
      | $file_instance?sha256='4376581c14355fcf38cc9fdb962b41b8fe68e2d6637efbfdbe10089ce8019c07' | $benchmark_type?name='illumina_isolate_reference_assembly'           |
    And the table "task" should contain "30" rows
    And the table "task_expanded_fields" should include the entries:
      | task_type | image_name                 | image_task |
      | produce   | bioboxes/velvet            | default    |
      | evaluate  | bioboxes/quast             | default    |
      | produce   | bioboxes/velvet            | careful    |
      | evaluate  | bioboxes/quast             | default    |


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


  Scenario: Migrating and loading the database with a non-standard camel case name
    Given an empty database without any tables
    And I copy the directory "../../tmp/input_data" to "data"
    And in bash I run:
    """
    mv data/inputs/data/amycolatopsis_sulphurea_dsm_46092.yml data/inputs/data/text1.yml
    """
    And the file "data/inputs/benchmark.yml" with:
      """
      ---
      - name: illumina_isolate_reference_assembly
        desc: Evaluate genome assemblers using reads and reference genome
        product_image_type: short_read_assembler
        evaluation_image_type: reference_assembly_evaluation
        data_sets:
          - ['text1', 'regular_fragment_1']
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

  Scenario: Migrating and loading the database when there are no images for a benchmark type
    Given an empty database without any tables
    And I copy the directory "../../tmp/input_data" to "data"
    And the file "data/inputs/image.yml" with:
      """
      ---
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
