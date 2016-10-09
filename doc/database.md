# Nucleotid.es relational data model

Nucleotid.es contains data from bioinformatics Docker images benchmarked
against sequencing data sets. These are organised using a relational database.
This documentation describes the fields in the tables in the nucleotid.es
database.

In additional to the fields listed below, each table has a primary key named
`id`, and a `created_at` listing the date the row was created. The database is
append only and rows are only added to each table, never deleted or updated.
SQL views using the `created_at` date are used to view the most recent state of
benchmarks. The reason for append-only is to preserve all benchmark data, such
as metrics for old versions of images, instead of replacing with new data.

## Docker Images

The following tables used the store information about the docker images used in
benchmarking.

### image_type

Categorises the different types of images used for benchmarking.

  * **name** - TEXT. The unique indentifer for a type of Docker image. An
    example is "short_read_assembler".

  * **description** - TEXT. A detailed description of the image type.

### image_instance

Lists all Docker images used.

  * **image_type_id** - INT. Foreign key for the `image_type` table.

  * **name** - VARCHAR. The name of a Docker image. An example is
    "bioboxes/velvet".

  * **sha256** - INT. The SHA256 digest of the Docker image file system layers,
    used to differentiate between different versions of images with the same
    name.

  * **active** - BOOLEAN. States whether the image should still be benchmarked.
    A false value indicates the image is deprecated. An image may be deprecated
    because it is no longer supported, or more likely because a new version is
    available. Differences in versions of images with the same name are
    identified by sha256 field.

There is table constraint that combinations of image_type_id, name, sha256
should be unique. This ensures there are no duplicated Docker images.

### image_instance_task

  * **image_instance_id** - INT. Foreign key for the `image_instance_table`

  * **task** - VARCHAR. The name of a task to run the image, examples are
    "default" or "careful".

  * **active** - BOOLEAN. Indicate whether the run mode should still be used. A
    false value indicates this run mode is deprecated.

There is table constraint that combinations of image_instance_id and task
should be unique. This ensures there are no duplicated tasks for the same
image.

## Input Data

Tables used to store the input data used the benchmarks. Examples of these may
be FASTQ files containing reads from sequencing and FASTA files containing the
improved draft quality genomes for comparison.

### source_type

Enumeration of the possible different biological sources used in nucleotides.

  * **name** - VARCHAR. The string name is used to indentify this source type,
    e.g. "microbe".

  * **description** - VARCHAR. Longer text description of the source type, e.g.
    "a single colony isolated microorganism".

### biological_source

Groups the different sets of data used for benchmarking by their name and
description.

  * **name** - VARCHAR. The string name is used to indentify this biological
    source, e.g. "amycolatopsis_sulphurea_dsm_46092".

  * **description** - VARCHAR. Longer text description of the biological
    source, e.g. "A microbe with a improved-draft reference genome generated
    using PacBio at the JGI."

  * **source_type_id" - INT. Foreign key to source_type table used to describe
    the type of biological source.

### input_data_file_set

Groups the different sets of data used for benchmarking by their name and
description.

  * **name** - VARCHAR. The string name is used to indentify the data when
    populating the database. Examples of this would be "regular_fragment"
    should be unique for each biological source.

  * **description** - VARCHAR. Examples are "Illumina 2x150 isolated microbe
    sequenced at the JGI".

  * **active** - BOOLEAN. Indicate whether this data set should still be used.
    A false value indicates this data set is deprecated.

  * **biological_source_id** - INT. Foreign key to the biological_source table
    from which this input data came from.

  * **platfom_type_id** - INT. Foreign key to the platform_type table used to
    identify what laboratory hardware was used to generate this data.

  * **protocol_type_id** - INT. Foreign key to the protocol_type table used to
    identify what laboratory protocol was used to generate this data.

  * **material_type_id** - INT. Foreign key to the material_type table used to
    identify what kind of biological material this data came from.

  * **extraction_method_type_id** - INT. Foreign key to the
    extraction_method_type table used to identify the laboratory material used
    to extract source material for this data.

  * **run_mode_type_id** - INT. Foreign key to the run_mode_type table used to
    describe what mode the laboratory hardware was run with to generate the
    source data.

### input_data_file

Many to many join table for input_data_file_set and file_instance table. Lists
all the files for each input data file set.

  * **input_data_file_set_id** - INT. Foreign key for the input file sets.

  * **file_instance_id** - INT. Foreign key the generic file instances table.

## input_data_file_expanded_fields

## Benchmarks

Tables to cross reference the data sets with the Docker images, and record the
results of benchmarking.

### benchmark_type

Maps the Docker image type to benchmark data type.

  * **name** - TEXT. The unique text indentifer for the benchmark type. An
    example is "short_read_assembler".

  * **product_image_type_id** - INT. Foreign key to the `image_type` table for
    the Docker image being benchmarked.

  * **evaluation_image_type_id** - INT. Foreign key to the `image_type` table
    for the Docker images being used to evaluated the produced data.

  * **data_set_id** - INT. Foreign key to the `data_set` table.

  * **active** - BOOLEAN. Indicate whether this data record should still be
    used. A false value indicates this data record is deprecated.


### benchmark_instance

A materialise view created from mapping each Docker `image_instance_task` to
each `data_record` via the m:n mappings in the `benchmark_type` table.

  * **benchmark_type_id** - INT. Foreign key to the `benchmark_type` table.

  * **data_instance_id** - INT. Foreign key to the `data_instance` table.

  * **image_instance_task_id** - INT. Foreign key to the `image_instance_task`
    table.

## Benchmarking Events

Tables for recording the results of benchmarking.

### event

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

