Feature: Migrating and loading input data for the database

  Scenario: Building the database with postgres variables
    Given an empty database without any tables
    And I copy the directory "../../test/data" to "data"
    When in bash I successfully run:
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
    And the table "data_set" should have the entries:
      | name              | description         |
      | jgi_isolate_2x150 | Verbose description |
    And the table "data_record" should have the entries:
      | entry_id | replicate | input_md5 | input_url  | reference_md5 | reference_url | reads   |
      | 1        | 1         | eaa53     | s3://url_1 | hexad         | s3://url_3    | 2000000 |
      | 1        | 2         | f01d2     | s3://url_2 | hexad         | s3://url_3    | 2000000 |
      | 2        | 1         | 42325     | s3://url_4 | hexad         | s3://url_5    | 2000000 |
    And the table "image_type" should have the entries:
      | name                    | description                                                                                 |
      | short_read_assembler    | Assembles paired Illumina short reads into contigs.                                         |
      | short_read_preprocessor | Performs filtering or editting of FASTQ reads and returns a subset or changed set of reads. |
    And the table "image_instance" should have the entries:
      | name                 | sha256   | active |
      | bioboxes/velvet      | digest_1 | t      |
      | bioboxes/velvet      | digest_1 | t      |
      | bioboxes/my-filterer | digest_3 | t      |
    And the table "benchmark_type" should have the entries:
      | name                                           |
      | illumina_isolate_reference_assembly            |
      | short_read_preprocessing_reference_evaluation  |
    And the table "benchmark_instance" should have the entries:
      | data_record_id                        | benchmark_type_id                                          |
      | $data_record?entry_id=2&replicate=1   | $benchmark_type?name='illumina_isolate_reference_assembly' |
    And the table "metric_type" should have the entries:
      | name | description                               |
      | ng50 | N50 normalised by reference genome length |


  Scenario: Building the database with RDS variables
    Given an empty database without any tables
    And I copy the directory "../../test/data" to "data"
    When in bash I successfully run:
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
