Feature: Migrating and loading input data for the database

  Scenario: Building the database
    Given an empty database without any tables
    And a directory "data"
    And a file named "data/images.yml" with:
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
    When I run `./bin/migrate data`
    Then the stderr should not contain anything
    And the exit status should be 0
    And the table "image_type" should have the entries:
      | name                 | description                                         |
      | short_read_assembler | Assembles paired Illumina short reads into contigs. |
