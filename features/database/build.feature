Feature: Migrating and loading input data for the database

  Scenario: Building the database
    Given an empty database without any tables
    When I run `./bin/migrate`
    Then the exit status should be 0
