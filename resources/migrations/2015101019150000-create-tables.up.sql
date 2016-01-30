--;;
--;; Metadata Types
--;;
--;; Copied from http://dba.stackexchange.com/questions/42924
CREATE OR REPLACE FUNCTION create_metadata_table(metadata_name varchar(30))
  RETURNS VOID AS
$func$
BEGIN
EXECUTE format('
  CREATE TABLE IF NOT EXISTS %I (
    id		serial		PRIMARY KEY,
    created_at	timestamp	DEFAULT current_timestamp,
    name	text		UNIQUE NOT NULL,
    description	text		NOT NULL,
    active	bool		NOT NULL DEFAULT true
  );', metadata_name || '_type');
END
$func$ LANGUAGE plpgsql;
--;;
DO $$
BEGIN
	PERFORM create_metadata_table('metric');
	PERFORM create_metadata_table('file');
	PERFORM create_metadata_table('image');

	PERFORM create_metadata_table('platform');
	PERFORM create_metadata_table('product');
	PERFORM create_metadata_table('run_mode');
	PERFORM create_metadata_table('protocol');
	PERFORM create_metadata_table('source');
END$$;
--;;
--;; Files
--;;
CREATE TABLE file_instance(
  id		serial		PRIMARY KEY,
  created_at	timestamp	DEFAULT current_timestamp,
  file_type_id	integer		NOT NULL REFERENCES file_type(id),
  sha256	text		UNIQUE NOT NULL,
  url		text		NOT NULL
);
--;;
--;; Input Data
--;;
CREATE TABLE input_data_source(
  id			serial		PRIMARY KEY,
  created_at		timestamp	DEFAULT current_timestamp,
  name			text		UNIQUE NOT NULL,
  description		text		NOT NULL,
  active		bool		NOT NULL DEFAULT true,
  source_type_id	integer		NOT NULL REFERENCES source_type(id)
);
--;;
CREATE TABLE input_data_source_reference_file(
  id			serial		PRIMARY KEY,
  created_at		timestamp	DEFAULT current_timestamp,
  active		bool		NOT NULL DEFAULT true,
  input_data_source_id	integer		NOT NULL REFERENCES input_data_source(id),
  file_instance_id	integer		NOT NULL REFERENCES file_instance(id),
  CONSTRAINT unique_reference_files_per_source_idx UNIQUE(input_data_source_id, file_instance_id)
);
--;;
CREATE TABLE input_data_file_set(
  id			serial		PRIMARY KEY,
  created_at		timestamp	DEFAULT current_timestamp,
  active		bool		NOT NULL DEFAULT true,
  name			text		UNIQUE NOT NULL,
  description		text		NOT NULL,
  input_data_source_id	integer		NOT NULL REFERENCES input_data_source(id),
  platform_type_id	integer		NOT NULL REFERENCES platform_type(id),
  product_type_id	integer		NOT NULL REFERENCES product_type(id),
  protocol_type_id	integer		NOT NULL REFERENCES protocol_type(id),
  run_mode_type_id	integer		NOT NULL REFERENCES run_mode_type(id)
);
--;;
CREATE TABLE input_data_file(
  id				serial		PRIMARY KEY,
  created_at			timestamp	DEFAULT current_timestamp,
  active			bool		NOT NULL DEFAULT true,
  input_data_file_set_id	integer		NOT NULL REFERENCES input_data_source(id),
  file_instance_id		integer		NOT NULL REFERENCES file_instance(id),
  CONSTRAINT unique_file_per_file_set_idx UNIQUE(input_data_file_set_id, file_instance_id)
);
--;;
--;; Docker images
--;;
CREATE TABLE image_instance(
  id		serial		PRIMARY KEY,
  created_at	timestamp	DEFAULT current_timestamp,
  image_type_id	integer		NOT NULL REFERENCES image_type(id),
  name		text		NOT NULL,
  sha256	text		NOT NULL,
  active	bool		NOT NULL DEFAULT true,
  CONSTRAINT image_instance_idx UNIQUE(image_type_id, name, sha256)
);
--;;
CREATE TABLE image_instance_task(
  id			serial		PRIMARY KEY,
  created_at		timestamp	DEFAULT current_timestamp,
  image_instance_id	integer		NOT NULL REFERENCES image_instance(id),
  task			text		NOT NULL,
  active		bool		NOT NULL DEFAULT true,
  CONSTRAINT image_instance_task_idx UNIQUE(image_instance_id, task)
);
--;;
--;; Benchmarks
--;;
CREATE TABLE benchmark_type(
  id				serial		PRIMARY KEY,
  created_at			timestamp	NOT NULL DEFAULT current_timestamp,
  name				text		UNIQUE NOT NULL,
  description			text		NOT NULL,
  product_image_type_id		integer		NOT NULL REFERENCES image_type(id),
  evaluation_image_type_id	integer		NOT NULL REFERENCES image_type(id),
  active			bool		NOT NULL DEFAULT true
);
--;;
CREATE TABLE benchmark_data(
  id				serial		PRIMARY KEY,
  created_at			timestamp	NOT NULL DEFAULT current_timestamp,
  input_data_file_set_id	integer		NOT NULL REFERENCES input_data_file_set(id),
  benchmark_type_id		integer		NOT NULL REFERENCES benchmark_type(id),
  active			bool		NOT NULL DEFAULT true,
  CONSTRAINT benchmark_data_idx UNIQUE(input_data_file_set_id, benchmark_type_id)
);
--;;
CREATE TABLE benchmark_instance(
  id					serial		PRIMARY KEY,
  created_at				timestamp	NOT NULL DEFAULT current_timestamp,
  external_id				text		UNIQUE NOT NULL,
  benchmark_type_id			integer		NOT NULL REFERENCES benchmark_type(id),
  input_data_file_id			integer		NOT NULL REFERENCES input_data_file(id),
  product_image_instance_id		integer		NOT NULL REFERENCES image_instance(id),
  product_image_instance_task_id	integer		NOT NULL REFERENCES image_instance_task(id),
  file_instance_id			integer		NOT NULL REFERENCES file_instance(id),
  CONSTRAINT benchmark_instance_idx UNIQUE(benchmark_type_id, input_data_file_id, product_image_instance_task_id)
);
--;;
CREATE OR REPLACE FUNCTION benchmark_instance_external_id() RETURNS trigger AS '
BEGIN
	NEW.external_id := md5(NEW.benchmark_type_id || ''-'' || NEW.input_data_file_id || ''-'' || NEW.product_image_instance_task_id);
	RETURN NEW;
END;' LANGUAGE plpgsql;
--;;
CREATE TRIGGER benchmark_instance_insert BEFORE INSERT OR UPDATE ON benchmark_instance FOR EACH ROW EXECUTE PROCEDURE benchmark_instance_external_id();
--;;
--;; Evaluation tasks
--;;
CREATE TYPE task_type AS ENUM ('produce', 'evaluate');
--;;
CREATE TABLE task(
  id				serial		PRIMARY KEY,
  created_at			timestamp	NOT NULL DEFAULT current_timestamp,
  benchmark_instance_id		integer		NOT NULL REFERENCES benchmark_instance(id),
  image_instance_task_id	integer		NOT NULL REFERENCES image_instance_task(id),
  task_type			task_type	NOT NULL,
  CONSTRAINT task_idx UNIQUE(benchmark_instance_id, image_instance_task_id, task_type)
);
--;;
CREATE INDEX task_type_idx ON task (task_type);
--;;
CREATE VIEW task_expanded_fields AS
SELECT
task.id,
task.benchmark_instance_id,
benchmark_instance.external_id,
task.task_type           AS task_type,
image_instance.name      AS image_name,
image_instance_task.task AS image_task,
image_instance.sha256    AS image_sha256,
image_type.name          AS image_type
FROM task
LEFT JOIN image_instance_task ON image_instance_task.id   = task.image_instance_task_id
LEFT JOIN image_instance      ON image_instance.id        = image_instance_task.image_instance_id
LEFT JOIN image_type          ON image_type.id            = image_instance.image_type_id
LEFT JOIN benchmark_instance  ON benchmark_instance.id    = task.benchmark_instance_id
