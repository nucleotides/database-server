Feature: Migrating and loading input data for the database

  Scenario: Building the database
    Given an empty database without any tables
    And a directory "data"
    And a file named "data/image.yml" with:
      """
      ---
      - image_type: short_read_assembler
        description: |
          Assembles paired Illumina short reads into contigs.
        image_instances:
          - image: bioboxes/velvet
            tasks:
              - default
              - careful
      """
    And a file named "data/data_type.yml" with:
      """
      ---
      - name: "isolate_2x150"
        protocol: "Illumina 2x150 paired reads"
        source: "Isolated microorganism"
      """
    When I run `./bin/migrate data`
    Then the exit status should be 0
    And the table "image_type" should have the entries:
      | name                 | description                                         |
      | short_read_assembler | Assembles paired Illumina short reads into contigs. |
    And the table "data_type" should have the entries:
      | name          | protocol                    | source                 |
      | isolate_2x150 | Illumina 2x150 paired reads | Isolated microorganism |
