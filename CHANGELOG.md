# Change Log

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](http://semver.org/).

## [v0.2.1] - date

### Added

  * Added a script within the docker image to start the migrations. The image
    CMD now runs the migrations and then launches the server. This means
    migrations will be run everytime the container is restarted.

## [v0.2.0] - 2015-01-06

### Changed

  * The API has been rewritten to use a postgres backend. The API now provides
    endpoints for listing outstanding tasks, and viewing completed benchmarks.

### Fixed

  * Fixed development bug where DOCKER_HOST url was hard coded into the test
    suite.
