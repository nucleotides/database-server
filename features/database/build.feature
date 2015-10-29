Feature: Migrating and loading input data for the database

  Scenario: Building the database
    Given an empty database without any tables
    And a directory "data"
    And a file named "data/data_type.yml" with:
      """
      ---
      - name: jgi_isolate_2x150
        library_protocol: Illumina 2x150 paired reads
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
    And a file named "data/benchmark_types.yml" with:
      """
      ---
      - data: short_read_isolate
        name: short_read_isolate_assembly
      - data: short_read_single_cell
        name: short_read_single_cell_assembly
      - data: short_read_isolate
        name: short_read_isolate_preprocessing
      """
    And a file named "data/image.yml" with:
      """
      ---
      - image_type: short_read_assembler
        description: |
          Assembles paired Illumina short reads into contigs.
        benchmarks:
          - short_read_isolate_assembly
          - short_read_single_cell_assembly
        image_instances:
          - image: bioboxes/velvet
            tasks:
              - default
              - careful
      """
    When I run `./bin/migrate data`
    Then the stderr excluding logging info should not contain anything
    And the exit status should be 0
    And the table "image_type" should have the entries:
      | name                 | description                                         |
      | short_read_assembler | Assembles paired Illumina short reads into contigs. |
    And the table "data_type" should have the entries:
      | name              | protocol                    | type              | description        |
      | jgi_isolate_2x150 | Illumina 2x150 paired reads | microbial_isolate | Verbose descripton |
    And the table "data_instance" should have the entries:
      | entry_id | replicate | input_md5 | input_url  | reference_md5 | reference_url | reads   |
      | 1        | 1         | eaa53     | s3://url_1 | hexad         | s3://url_3    | 2000000 |
      | 1        | 2         | f01d2     | s3://url_2 | hexad         | s3://url_3    | 2000000 |
      | 2        | 1         | 42325     | s3://url_3 | hexad         | s3://url_5    | 2000000 |
