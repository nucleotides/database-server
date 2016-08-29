--;;
--;; Metadata Types
--;;
--;; Copied from http://dba.stackexchange.com/questions/42924
CREATE OR REPLACE FUNCTION create_metadata_table(metadata_name varchar(50))
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
	PERFORM create_metadata_table('run_mode');
	PERFORM create_metadata_table('protocol');
	PERFORM create_metadata_table('source');
	PERFORM create_metadata_table('extraction_method');
	PERFORM create_metadata_table('material');
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
CREATE TABLE biological_source(
  id			serial		PRIMARY KEY,
  created_at		timestamp	DEFAULT current_timestamp,
  name			text		UNIQUE NOT NULL,
  description		text		NOT NULL,
  active		bool		NOT NULL DEFAULT true,
  source_type_id	integer		NOT NULL REFERENCES source_type(id)
);
--;;
CREATE TABLE biological_source_reference_file(
  id			serial		PRIMARY KEY,
  created_at		timestamp	DEFAULT current_timestamp,
  active		bool		NOT NULL DEFAULT true,
  biological_source_id	integer		NOT NULL REFERENCES biological_source(id),
  file_instance_id	integer		NOT NULL REFERENCES file_instance(id),
  CONSTRAINT unique_reference_files_per_source_idx UNIQUE(biological_source_id, file_instance_id)
);
--;;
CREATE TABLE input_data_file_set(
  id				serial		PRIMARY KEY,
  created_at			timestamp	DEFAULT current_timestamp,
  active			bool		NOT NULL DEFAULT true,
  name				text		NOT NULL,
  description			text		NOT NULL,
  biological_source_id		integer		NOT NULL REFERENCES biological_source(id),
  platform_type_id		integer		NOT NULL REFERENCES platform_type(id),
  protocol_type_id		integer		NOT NULL REFERENCES protocol_type(id),
  material_type_id		integer		NOT NULL REFERENCES material_type(id),
  extraction_method_type_id	integer		NOT NULL REFERENCES extraction_method_type(id),
  run_mode_type_id		integer		NOT NULL REFERENCES run_mode_type(id),
  CONSTRAINT unique_files_set_per_source_idx UNIQUE(name, biological_source_id)
);
--;;
CREATE TABLE input_data_file(
  id				serial		PRIMARY KEY,
  created_at			timestamp	DEFAULT current_timestamp,
  active			bool		NOT NULL DEFAULT true,
  input_data_file_set_id	integer		NOT NULL REFERENCES input_data_file_set(id),
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
  name		text		UNIQUE NOT NULL,
  active	bool		NOT NULL DEFAULT true
);
--;;
CREATE TABLE image_version(
  id			serial		PRIMARY KEY,
  created_at		timestamp	DEFAULT current_timestamp,
  image_instance_id	integer		NOT NULL REFERENCES image_instance(id),
  name			text		NOT NULL,
  sha256		text		UNIQUE NOT NULL,
  active		bool		NOT NULL DEFAULT true
  CONSTRAINT image_name_idx UNIQUE(image_instance_id, name)
);
--;;
CREATE TABLE image_task(
  id			serial		PRIMARY KEY,
  created_at		timestamp	DEFAULT current_timestamp,
  image_version_id	integer		NOT NULL REFERENCES image_version(id),
  name			text		NOT NULL,
  active		bool		NOT NULL DEFAULT true,
  CONSTRAINT image_task_idx UNIQUE(image_version_id, name)
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
  id				serial		PRIMARY KEY,
  created_at			timestamp	NOT NULL DEFAULT current_timestamp,
  external_id			text		UNIQUE NOT NULL,
  benchmark_type_id		integer		NOT NULL REFERENCES benchmark_type(id),
  input_data_file_id		integer		NOT NULL REFERENCES input_data_file(id),
  product_image_instance_id	integer		NOT NULL REFERENCES image_instance(id),
  product_image_version_id	integer		NOT NULL REFERENCES image_task(id),
  product_image_task_id		integer		NOT NULL REFERENCES image_task(id),
  file_instance_id		integer		NOT NULL REFERENCES file_instance(id),
  CONSTRAINT benchmark_instance_idx UNIQUE(benchmark_type_id, input_data_file_id, product_image_task_id)
);
--;;
CREATE OR REPLACE FUNCTION benchmark_instance_external_id() RETURNS trigger AS '
BEGIN
	NEW.external_id := md5(NEW.benchmark_type_id || ''-'' || NEW.input_data_file_id || ''-'' || NEW.product_image_task_id);
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
  image_task_id			integer		NOT NULL REFERENCES image_task(id),
  task_type			task_type	NOT NULL,
  CONSTRAINT task_idx UNIQUE(benchmark_instance_id, image_task_id, task_type)
);
--;;
CREATE INDEX task_type_idx ON task (task_type);
--;;
--;; Events
--;;
CREATE TABLE event(
  id		serial		PRIMARY KEY,
  created_at	timestamp	NOT NULL DEFAULT current_timestamp,
  task_id	integer		NOT NULL REFERENCES task(id),
  success	bool 		NOT NULL
);
--;;
CREATE INDEX event_status ON event (success);
--;;
CREATE TABLE event_file_instance(
  id			serial		PRIMARY KEY,
  event_id		integer		NOT NULL REFERENCES event(id),
  file_instance_id	integer 	NOT NULL REFERENCES file_instance(id),
  CONSTRAINT event_file_idx UNIQUE(event_id, file_instance_id)
);
--;;
--;; Metrics
--;;
CREATE TABLE metric_instance(
  id			serial		PRIMARY KEY,
  created_at		timestamp	DEFAULT current_timestamp,
  metric_type_id	integer		NOT NULL REFERENCES metric_type(id),
  event_id		integer		NOT NULL REFERENCES event(id),
  value			float 		NOT NULL,
  CONSTRAINT metric_to_event UNIQUE(metric_type_id, event_id)
);
--;;
--;; Expanded view of tasks
--;;
CREATE VIEW task_expanded_fields AS
WITH successful_event AS (
  SELECT DISTINCT ON (task_id)
  task_id
  FROM event
  WHERE success = TRUE
)
SELECT
task.id,
task.benchmark_instance_id,
benchmark_instance.external_id,
task.task_type           AS task_type,
image_instance.name      AS image_name,
image_version.sha256     AS image_sha256,
image_task.name          AS image_task,
image_type.name          AS image_type,
successful_event.task_id IS NOT NULL AS complete
FROM task
LEFT JOIN image_task      ON image_task.id     = task.image_task_id
LEFT JOIN image_version   ON image_version.id  = image_task.image_version_id
LEFT JOIN image_instance  ON image_instance.id = image_version.image_instance_id
LEFT JOIN image_type          ON image_type.id            = image_instance.image_type_id
LEFT JOIN benchmark_instance  ON benchmark_instance.id    = task.benchmark_instance_id
LEFT JOIN successful_event    ON successful_event.task_id = task.id;
--;;
--;; Functions for populating benchmark_instance and task
--;;
CREATE FUNCTION populate_benchmark_instance () RETURNS void AS $$
BEGIN
INSERT INTO benchmark_instance(
	benchmark_type_id,
	input_data_file_id,
	product_image_instance_id,
	product_image_version_id,
	product_image_task_id,
	file_instance_id)
SELECT
benchmark_type.id      AS benchmark_type_id,
input_data_file.id     AS data_file_id,
image_instance.id      AS image_instance_id,
image_version.id       AS image_version_id,
image_task.id          AS image_task_id,
file_instance.id       AS file_instance_id
FROM benchmark_type
LEFT JOIN benchmark_data      ON benchmark_data.benchmark_type_id = benchmark_type.id
LEFT JOIN input_data_file_set ON input_data_file_set.id = benchmark_data.input_data_file_set_id
LEFT JOIN input_data_file     ON input_data_file.input_data_file_set_id = input_data_file_set.id
LEFT JOIN file_instance       ON file_instance.id = input_data_file.file_instance_id
LEFT JOIN image_type          ON image_type.id = benchmark_type.product_image_type_id
INNER JOIN image_instance     ON image_instance.image_type_id = image_type.id
LEFT JOIN image_version       ON image_version.image_instance_id = image_instance.id
LEFT JOIN image_task          ON image_task.image_version_id = image_instance.id
ON CONFLICT DO NOTHING;
END; $$
LANGUAGE PLPGSQL;
--;;
CREATE FUNCTION populate_task () RETURNS void AS $$
BEGIN
INSERT INTO task (benchmark_instance_id, image_task_id, task_type)
	SELECT
	benchmark_instance.id   AS benchmark_instance_id,
	image_task.id           AS image_task_id,
	'evaluate'::task_type   AS task_type
	FROM benchmark_instance
	LEFT JOIN benchmark_type      ON benchmark_type.id = benchmark_instance.benchmark_type_id
	LEFT JOIN image_instance      ON image_instance.image_type_id = benchmark_type.evaluation_image_type_id
	LEFT JOIN image_version       ON image_version.image_instance_id = image_instance.id
	LEFT JOIN image_task          ON image_task.image_version_id = image_instance.id
UNION
	SELECT
	benchmark_instance.id	                 AS benchmark_instance_id,
	benchmark_instance.product_image_task_id AS image_task_id,
	'produce'::task_type                     AS task_type
	FROM benchmark_instance
EXCEPT
	SELECT
	benchmark_instance_id,
	image_task_id,
	task_type
	FROM task
ORDER BY benchmark_instance_id, image_task_id, task_type ASC;
END; $$
LANGUAGE PLPGSQL;
