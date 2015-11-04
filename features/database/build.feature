Feature: Migrating and loading input data for the database

  Scenario: Building the database
    Given an empty database without any tables
    And a directory "data"
    And a file named "data/data.yml" with:
      """
      ---
      - name: jgi_isolate_2x150
        library: Illumina 2x150 paired reads
        type: short_read_isolate
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
      - image_type: short_read_preprocessor
        description: |
          Performs filtering or editting of FASTQ reads and returns a subset or changed set of reads.
        image_instances:
          - name: bioboxes/my-filterer
            sha256: digest_2
            tasks:
              - default
      """
    And a file named "data/benchmark_type.yml" with:
      """
      ---
      - name: short_read_isolate_assembly
        data_type: short_read_isolate
        image_type: short_read_assembler
      - name: short_read_isolate_preprocessing
        data_type: short_read_isolate
        image_type: short_read_preprocessor
      """
    When I run `./bin/migrate data`
    Then the stderr excluding logging info should not contain anything
    And the exit status should be 0
    And the table "data_type" should have the entries:
      | name              | library                     | type               | description         |
      | jgi_isolate_2x150 | Illumina 2x150 paired reads | short_read_isolate | Verbose description |
    And the table "data_instance" should have the entries:
      | entry_id | replicate | input_md5 | input_url  | reference_md5 | reference_url | reads   |
      | 1        | 1         | eaa53     | s3://url_1 | hexad         | s3://url_3    | 2000000 |
      | 1        | 2         | f01d2     | s3://url_2 | hexad         | s3://url_3    | 2000000 |
      | 2        | 1         | 42325     | s3://url_4 | hexad         | s3://url_5    | 2000000 |
    And the table "image_type" should have the entries:
      | name                    | description                                                                                 |
      | short_read_assembler    | Assembles paired Illumina short reads into contigs.                                         |
      | short_read_preprocessor | Performs filtering or editting of FASTQ reads and returns a subset or changed set of reads. |
    And the table "image_task" should have the entries:
      | name                 | task    | sha256   | active |
      | bioboxes/velvet      | default | digest_1 | t      |
      | bioboxes/velvet      | careful | digest_1 | t      |
      | bioboxes/my-filterer | default | digest_2 | t      |
    And the table "benchmark_type" should have the entries:
      | name                             |
      | short_read_isolate_assembly      |
      | short_read_isolate_preprocessing |
