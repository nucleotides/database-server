# Nucleotid.es relational data model

Nucleotid.es contains data from different Docker images benchmarked on
different sequencing data sets. These are organised using a relational
database. In additional to the fields listed each table has a primary key named
`id`, and a `timestamp` listing the data the row was added. The tables are
organsised as follows:

## Docker Images

Tables used the store the docker images instances used in benchmarking

### image_type

Categorises the different kinds of images used for benchmarking.

  * **name** - TEXT. Examples are "short_read_assembler". This field is unique
    as there should not be duplicated types.

  * **description** - TEXT. A more detailed description of the image type.

### image_task

Lists the available tasks for available Docker images.

  * **image_type_id** - INT. Foreign key for the image_type table.

  * **name** - VARCHAR. The name of the Docker image. examples are
    "bioboxes/velvet".

  * **task** - VARCHAR. The name of a task to run the image, examples are
    "default".

  * **sha256** - INT. The SHA256 digest of the Docker image file system layers,
    used to differentiate between difference versions images with the same
    name.

  * **active** - BOOLEAN. States whether the image should still be benchmarked.
    A false value indicates the image is deprecated. An image may be deprecated
    because it is no longer support, or more likely because a new version is
    created. Differences in versions of images with the same name are
    identified by sha256 field.

There is table constraint that combinations of image_type_id, name, task,
sha256 should be unique. This ensures there are no duplicated Docker image
tasks.

## Sequencing Data

Tables used to store the data used in benchmarking

### data_type

Categorises the different kinds of data used for benchmarking.

  * **description** - VARCHAR. Examples are "Illumina 2x150 sequenced at the
    JGI".

### data_instance

Lists the individual files locations which contain the data used for
benchmarking and evaluating the output.

  * **data_type_id** - INT. Foreign key to the data_type table.

  * **replicate** - INT. The replicate number for this data.

  * **input_url** - VARCHAR. The URL where the input data can be found.

  * **reference_url** - VARCHAR. The URL where the reference data can be found.

  * **input_md5sum** - INT. The md5sum of the input data file.

  * **reference_md5sum** - VARCHAR. The md5sum of the reference data file.

## Benchmarks

Tables for cross referencing the benchmarking of Docker images on data sets.

### benchmark_type

Maps the Docker image type to benchmark data type.

  * **image_type_id** - INT. Foreign key to the image type table.

  * **data_type_id** - INT. Foreign key to the data type table.

### benchmark_instance

Maps individual Docker image tasks to individual data files.

  * **benchmark_type_id** - INT. Foreign key to the benchmark type table.

  * **image_task_id** - INT. Foreign key to the image task table.

  * **data_instance_id** - INT. Foreign key to the data instance table.

## Benchmarking Events

Tables for recording the results of benchmarking datasets.

### benchmark_event_status

Description of the status of benchmarking events.

  * **name** - VARCHAR. Short name for the status.

  * **description** - INT. Description of this status.

### benchmark_event

Record benchmark events as they occur.

  * **benchmark_instance_id** - INT. Foreign key to benchmark instance table.

  * **benchmarking_event_status_id** - INT. Foreign key to status table.

### metric_type

Describe the metrics used for benchmarking.

  * **name** - VARCHAR. Short name for the metric.

  * **description** - VARCHAR. Longer description of the metric.

### metric_instance

Record values for benchmark metrics.

  * **metric_type_id** - INT. Foreign key to the metric type table

  * **benchmark_event_id** - INT. Foreign key to the benchmark_event_id table.

  * **value** - DOUBLE. Estimated metric value from benchmarking.
