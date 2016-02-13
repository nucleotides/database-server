# Change Log

All notable changes to this project will be documented in this file. This
project adheres to Semantic Versioning(http://semver.org/).

## v0.5.1 - 2015-02-12

### Changed

  * Reduced docker image size by switching to an Alpine Linux base image.

  * Improved database perfomance by using a connection pool.


## v0.5.0 - 2015-02-10

### Changed

  * GET `/tasks/show.json` now returns a list containing only the IDs of
    outstanding benchmarking tasks. The benchmarking client is then responsible
    for getting the task metadata from `task/:id`. This is slightly more
    efficient than multiple joins to fetch all metadata for each task.

  * Benchmarking tasks are now associated with multiple input files instead of
    a one-to-one relationship between file and benchmark. This fixes the issue
    where a genome assembly evaluation task needs two input files: the produced
    assembly and the reference genome.

  * Refactored data model for the reference and input data used in
    benchmarking. The updated data model makes it simpler to describe and
    organise the different benchmarking data sets by their metadata. A
    top-level entity was added: 'data source'. This tracks the metadata and any
    associated reference files. All input data and reference files descend from
    this 'data source' entity and can therefore be linked back to this
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
