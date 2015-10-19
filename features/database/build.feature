Feature: Migrating and loading input data for the database

  Scenario: Building the database
    When I run `./bin/migrate`
    Then the stderr should not contain anything
    And the exit status should be 0
