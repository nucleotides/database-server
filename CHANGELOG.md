# Change Log

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](http://semver.org/).

## v0.9.1 - 2016-10-28

### Added

  * Set `Content-Disposition` header in `/results/complete` returned response.
    The ensures the downloaded file has the correct file extension.

### Changed

  * `/status.json` returns contig count in millions as
    `n_millions_of_contigs_generated` instead of `n_contigs_generated`.

### Fixed

  * `cpu_time_in_days` now correctly returned in `/status.json`

## v0.9.0 - 2016-10-27

### Added

  * Added `/status.json` API route. This shows the current status of the tasks
    and the benchmarks in the nucleotides database. This provides a global view
    of how the benchmarking is proceeding.

  * Added `/results/complete` API route. This allows the collection of the
    completed benchmarking results in either JSON or CSV format using the
    `?format=json` query parameters. This returns only the results for the
    image tasks when all benchmarking tasks related to that image task have
    been completed. If any benchmarking tasks have failed or not been completed
    then all the metrics for that image task are not returned.

  * Created `input_data_file_expanded_fields` materialised view for input data
    files tables. This is a denormalised table of all the tables related to
    input files, with the addition of indices for all foreign key IDs, includes
    the common joins of input_data_file, input_data_file_set,
    biological_source, and biological_source_type.

  * Created `image_expanded_fields` materialised view for Docker image tables.
    This is a denormalised table of all the tables related Docker images, with
    the addition of indices for all foreign key IDs, includes the common joins
    of image_type, image_instance, image_version, and image_task.

  * Created `events_prioritised_by_successful` view showing events for each
    task prioritised by completion status and oldest first.

  * Created `benchmark_instance_name` view providing a name for a benchmark
    instance from the concatenated sub fields.

  * Create `rebuild_benchmarks` function providing a single database function
    call to refresh all materialised vies, add any additional rows to the
    benchmark instance and task table, and reindex these tables.

### Changed

  * Simplified the populate_benchmark_instance, and populate_task functions to
    use the two materialised views image_expanded_fields,
    input_data_file_expanded_fields. As less joins are required with the
    materialised views the two queries in these functions are simpler.

  * Renamed all database primary keys to be explicitly named after the table,
    e.g. `task.id` is now `task.task_id`. The aim of this change is to prevent
    tables being accidentally joined on the wrong primary keys through human
    error. The cause of this is two tables can be accidentally joined on the
    `.id` column when because all tables use this column name as the primary
    key. Explicitly naming the primary keys means two tables in a join must
    have matching primary and foreign keys. This will not eliminate human error
    when writing joins but should hopefully reduce the chance of it happening.

  * Simplified existing and added additional feature tests for more complex
    input data during migration of database. This feature test simulates
    different combinations of benchmarks, input data sets, image versions and
    tasks, and evaluation tasks. The aim is to add stricter tests for the
    importing of data.

  * Unsuccessful benchmarking tasks no longer appear in `/tasks/show.json`.

  * Benchmarking tasks in `/tasks/show.json` are shorted by SHA256 digest to
    ensure that similar image benchmarks are run on the same machine as much as
    possible.

  * Tasks returned in `/tasks/:id`, and benchmarks returned in
    `/benchmarks/:id` now have `success` boolean field. This indicates if the
    task or benchmark was successfully completed. The `complete` field denotes
    whether the task or benchmark was completed at all. A task or benchmark
    will appear as completed if the tasks were attempted but unsuccessful.

### Fixed

  * Nucleotides input data containing benchmarks without Docker images or input
    file sets, and input file sets without files no longer throws a database
    error.

  * Fixed bug in population of benchmarking tasks where Docker image tables
    were accidently joined on the wrong columns.

## v0.8.2 - 2016-09-29

  * Fixed bug where the code transforming the keyword file name in the input
    file dictionary back to a snake case string for use in the database added
    underscores between a characters and a numbers treating them as a word
    boundaries. This code was removed and strings were used for file names.

## v0.8.1 - 2016-09-06

### Fixed

  * Fixed bug where database benchmark ID was hard coded into SQL query for
    evaluate input files. Added test to ensure database IDs are not hard coded
    in future.

## v0.8.0 - 2016-09-01

### Added

  * The API supports version strings for the biobox images.

### Fixed

  * When multiple successful produce events are available for an evaluate event
    only the first event is used to select which input files are used. This
    ensures there will be problems arising from multiple files are the same
    type being provided for an evaluate task.

## v0.7.0 - 2016-05-03

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
