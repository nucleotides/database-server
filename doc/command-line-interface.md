# Command line interface

The nucleotid.es API has two CLI scripts. These are:

  * `bin/migrate` - creates the database and loads the initial nucleotid.es
    Docker image and benchmarking data.

  * `bin/server` - starts the API server as a blocking process

## Migrate

The migrate script will create the tables and initial benchmarking data
required by nucleotid.es in a postgreSQL database. This script requires
environment parameters for the database to be set. The required parameters are:

  * POSTGRES_USER
  * POSTGRES_PASSWORD
  * POSTGRES_NAME
  * POSTGRES_HOST

The host parameter should also include the port number and should be in the
form `//ADDRESS:PORT`. An example postgres host might be `//0.0.0.0:5432`, and
in many cases this will be the location of the database. The migrations are run
as:

~~~ bash
./bin/migrate data_folder
~~~

The `data_folder` should contain YAML files with the initial benchmarking data
to populate the nucleotid.es database. The files in this folder are:

  * **image.yml** - this lists all the images that should be benchmarked. These
    data are used to populate the **image_types** and **image_tasks** table.
