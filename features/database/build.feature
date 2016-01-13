Feature: Migrating and loading input data for the database

  Scenario: Building the database
    Given an empty database without any tables
    And a directory "data"
    And a file named "data/data.yml" with:
      """
      ---
      - name: jgi_isolate_2x150
        description: Verbose description
        entries:
          - reads: 2000000
            entry_id: 1
            replicates:
              - md5sum: eaa53
                url: s3://url_1
              - md5sum: f01d2
                url: s3://url_2
            reference:
              md5sum: hexad
              url: s3://url_3
          - reads: 2000000
            entry_id: 2
            replicates:
              - md5sum: 42325
                url: s3://url_4
            reference:
              md5sum: hexad
              url: s3://url_5
      """
    And a file named "data/image.yml" with:
      """
      ---
      - image_type: short_read_assembler
        description: |
          Assembles paired Illumina short reads into contigs.
        image_instances:
          - name: bioboxes/velvet
            sha256: digest_1
            tasks:
              - default
              - careful
          - name: bioboxes/ray
            sha256: digest_2
            tasks:
              - default
      - image_type: short_read_preprocessor
        description: |
          Performs filtering or editting of FASTQ reads and returns a subset or changed set of reads.
        image_instances:
          - name: bioboxes/my-filterer
            sha256: digest_3
            tasks:
              - default
      - image_type: reference_assembly_evaluation
        description: |
          Evaluates the quality of an assembly using a reference genome
        image_instances:
          - name: bioboxes/quast
            sha256: digest_4
            tasks:
              - default
      - image_type: short_read_preprocessing_reference_evaluation
        description: |
          Evaluates the quality of short read preprocessing using a reference genome
        image_instances:
          - name: bioboxes/velvet-then-quast
            sha256: digest_4
            tasks:
              - default
      """
    And a file named "data/benchmark_type.yml" with:
      """
      ---
      - name: illumina_isolate_reference_assembly
        product_image_type: short_read_assembler
        evaluation_image_type: reference_assembly_evaluation
        data_sets:
          - jgi_isolate_2x150
      - name: short_read_preprocessing_reference_evaluation
        product_image_type: short_read_preprocessor
        evaluation_image_type: short_read_preprocessing_reference_evaluation
        data_sets:
          - jgi_isolate_2x150
      """
    And a file named "data/metric_type.yml" with:
      """
      ---
      - name: ng50
        description: N50 normalised by reference genome length
      - name: lg50
        description: L50 normalised by reference genome length
      """
    When in bash I successfully run:
      """
      docker run \
        --env=POSTGRES_HOST=//localhost:5432 \
        --env=POSTGRES_USER=${POSTGRES_USER} \
        --env=POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
        --env=POSTGRES_NAME=${POSTGRES_NAME} \
        --volume=$(realpath data):/data:ro \
        --net=container:$(cat ../../.rdm_container) \
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
