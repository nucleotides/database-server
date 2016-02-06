# Change Log

All notable changes to this project will be documented in this file. This
project adheres to Semantic Versioning(http://semver.org/).

## Unreleased

### Changed

  * GET `/tasks/show.json` now returns a list of only the task IDs. The
    benchmarking client is then responsible for getting the task metadata from
    `task/:id`.

  * Benchmarking tasks are now associated with multiple input files instead of
    one file per task. This fixes the bug where a genome assembly evaluation
    task needs the produced assembly and the reference genome as input files.

  * Refactored data model for the input data used for benchmarking. The updated
    data model makes it simpler to describe and organise the different
    benchmarking data sets by their metadata. A top-level entity 'data source'
    tracks metadata and any associated reference files. All data files descend
    from a 'data source' entity and can therefore be linked back to the
    metadata.

## v0.4.0 - 2015-01-20

### Added

  * Added `/tasks/:id` - this provides a URL for getting metadata about a
    single task.

## v0.3.0 - 2015-01-14

### Fixed

  * Running migrations with files containing same data and images in the input
    files no longer creates an SQL error from trying to insert a duplicate row
    with index constraints. Instead the duplicate rows are skipped. This allows
    migrations to be run repeatedly, the intended behaviour, when adding new
    data and images to the input files.

## v0.2.3 - 2015-01-13

### Fixed

  * Don't show evaluation tasks in `/tasks/show.json` for which there are no
    produced input data available.

## v0.2.2 - 2015-01-13

### Added

  * Initialisation scripts can optionally use RDS environment variables as set
    by elastic beanstalk.

## v0.2.1 - 2015-01-08

### Added

  * Added a script within the docker image to start the migrations. The Docker
    image CMD now runs the migrations and then launches the server. This means
    migrations will be run every time the container is restarted or launched.

## v0.2.0 - 2015-01-06

### Changed

  * The API has been rewritten to use a postgres back end. The API now provides
    endpoints for listing outstanding tasks, and viewing completed benchmarks.

### Fixed

  * Fixed development bug where DOCKER_HOST URL was hard coded into the test
    suite.
