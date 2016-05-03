# Change Log

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](http://semver.org/).

## v0.7.0 - 2015-05-03

### Changed

  * The nucleotides input file release [bb895e1][] now support multiple
    versions of the same image using the SHA256 of the image to distinguish
    them. This release supports multiple image versions through an additional
    database table `image_version`. The API however is unchanged.

[bb895e1]: https://github.com/nucleotides/nucleotides-data/commit/bb895e180a12b6bd6788b500a7a52fb587e7504c

## v0.6.0 - 2016-04-13

### Changed

  * The nucleotides input files have been significantly changed with release
    [96abff940b][] of the nucleotides-data repository. This version supports
    these changes in the backend database and in the migration and import of
    the data. The API however is still unchanged.

[96abff940b]: https://github.com/nucleotides/nucleotides-data/commit/96abff940b9b44825071d76b2c0907791f03e7c3

## v0.5.4 - 2016-03-11

### Added

  * Added checks for metric and file types in /event POST requests. If a
    request is sent with an unknown metric or file type a 422 error code is
    returned, listing the unknown values. This fixes the previous 500 error
    code returned when an internal database error occurred.

  * Return 404 HTTP codes when trying to get an event, task, or benchmark
    resource which does not exist.

### Fixed

  * Handle identical files in POST requests. There exists the possibility that
    two identical files will be created during benchmarking. These files will
    have identical SHA256 digests, which a database error as the SHA256 is the
    primary key in the file table. This fix handles identical files by skipping
    the creation, and instead linking the existing file to the new event table
    entry.

### Changed

  * Internally, the API routes were converted to [liberator][] resources. This
    allowed the separation of the code for searching the database and the code
    for responding to HTTP requests. This overall should simplify the
    maintenance of the project, an example is returning the appropriate 404 and
    422 error codes included in this release.

[liberator]: http://clojure-liberator.github.io/liberator/

## v0.5.3 - 2016-02-25

### Changed

  * Created jar file is last line in Dockerfile. This should prevent cached
    file system layers being repeated 'popped' when the jar file is updated
    with a new version.

## v0.5.2 - 2016-02-25

### Added

  * GET /task/:id now returns all the events associated with that task. This
    allows the completed events to be viewed for each task.

## v0.5.1 - 2016-02-12

### Changed

  * Reduced docker image size by switching to an Alpine Linux base image.

  * Improved database performance by using a connection pool.

  * Updated dependency libraries to latest versions

  * Removed no longer used AWS SDB code module

## v0.5.0 - 2016-02-10

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

## v0.4.0 - 2016-01-20

### Added

  * Added `/tasks/:id` - this provides a URL for getting metadata about a
    single task.

## v0.3.0 - 2016-01-14

### Fixed

  * Running migrations with files containing same data and images in the input
    files no longer creates an SQL error from trying to insert a duplicate row
    with index constraints. Instead the duplicate rows are skipped. This allows
    migrations to be run repeatedly, the intended behaviour, when adding new
    data and images to the input files.

## v0.2.3 - 2016-01-13

### Fixed

  * Don't show evaluation tasks in `/tasks/show.json` for which there are no
    produced input data available.

## v0.2.2 - 2016-01-13

### Added

  * Initialisation scripts can optionally use RDS environment variables as set
    by elastic beanstalk.

## v0.2.1 - 2016-01-08

### Added

  * Added a script within the docker image to start the migrations. The Docker
    image CMD now runs the migrations and then launches the server. This means
    migrations will be run every time the container is restarted or launched.

## v0.2.0 - 2016-01-06

### Changed

  * The API has been rewritten to use a postgres back end. The API now provides
    endpoints for listing outstanding tasks, and viewing completed benchmarks.

### Fixed

  * Fixed development bug where DOCKER_HOST URL was hard coded into the test
    suite.
