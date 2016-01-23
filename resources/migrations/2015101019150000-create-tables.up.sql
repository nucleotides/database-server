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
	PERFORM create_metadata_table('platform');
	PERFORM create_metadata_table('metric');
	PERFORM create_metadata_table('file');
	PERFORM create_metadata_table('image');
END$$;
--;;
--;; Files
--;;
CREATE TABLE file_instance(
  id		serial		PRIMARY KEY,
  created_at	timestamp	DEFAULT current_timestamp,
  file_type_id	integer		NOT NULL REFERENCES file_type(id),
  md5		text		NOT NULL,
  url		text		NOT NULL
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
--;; Data sets
--;;
CREATE TABLE data_set(
  id           serial          PRIMARY KEY,
  created_at   timestamp       NOT NULL DEFAULT current_timestamp,
  name         text            UNIQUE NOT NULL,
  description  text            NOT NULL,
  active       bool            NOT NULL DEFAULT true
);
--;;
CREATE TABLE data_record(
  id		serial		PRIMARY KEY,
  created_at	timestamp	NOT NULL DEFAULT current_timestamp,
  data_set_id	integer		NOT NULL REFERENCES data_set(id),
  entry_id	integer		NOT NULL,
  replicate	integer		NOT NULL,
  reads		integer		NOT NULL,
  input_url	text		NOT NULL,
  reference_url	text		NOT NULL,
  input_md5	text		NOT NULL,
  reference_md5	text		NOT NULL,
  active	bool		NOT NULL DEFAULT true,
  CONSTRAINT data_replicates UNIQUE(data_set_id, entry_id, replicate)
);
--;;
--;; Benchmarks
--;;
CREATE TABLE benchmark_type(
  id				serial		PRIMARY KEY,
  created_at			timestamp	NOT NULL DEFAULT current_timestamp,
  name				text		UNIQUE NOT NULL,
  product_image_type_id		integer		NOT NULL REFERENCES image_type(id),
  evaluation_image_type_id	integer		NOT NULL REFERENCES image_type(id),
  active			bool		NOT NULL DEFAULT true
);
--;;
CREATE TABLE benchmark_data(
  id			serial		PRIMARY KEY,
  created_at		timestamp	NOT NULL DEFAULT current_timestamp,
  data_set_id		integer		NOT NULL REFERENCES data_set(id),
  benchmark_type_id	integer		NOT NULL REFERENCES benchmark_type(id),
  active		bool		NOT NULL DEFAULT true,
  CONSTRAINT benchmark_data_idx UNIQUE(data_set_id, benchmark_type_id)
);
--;;
CREATE TABLE benchmark_instance(
  id					serial		PRIMARY KEY,
  created_at				timestamp	NOT NULL DEFAULT current_timestamp,
  external_id				text		UNIQUE NOT NULL,
  benchmark_type_id			integer		NOT NULL REFERENCES benchmark_type(id),
  data_record_id			integer		NOT NULL REFERENCES data_record(id),
  product_image_instance_task_id	integer		NOT NULL REFERENCES image_instance_task(id),
  CONSTRAINT benchmark_instance_idx UNIQUE(data_record_id, product_image_instance_task_id)
);
CREATE OR REPLACE FUNCTION benchmark_instance_external_id() RETURNS trigger AS '
BEGIN
	NEW.external_id := md5(NEW.benchmark_type_id || ''-'' || NEW.data_record_id || ''-'' || NEW.product_image_instance_task_id);
	RETURN NEW;
END;' LANGUAGE plpgsql;
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
CREATE INDEX task_type_idx ON task (task_type);
--;;
CREATE TABLE event(
  id		serial		PRIMARY KEY,
  created_at	timestamp	NOT NULL DEFAULT current_timestamp,
  task_id	integer		NOT NULL REFERENCES task(id),
  file_url	text,
  file_md5	text,
  log_file_url	text		NOT NULL,
  success	bool		NOT NULL
);
--;;
--;; Metrics
--;;
CREATE TABLE metric_instance(
  id			serial		PRIMARY KEY,
  created_at		timestamp	DEFAULT current_timestamp,
  metric_type_id	integer		NOT NULL REFERENCES metric_type(id),
  event_id		integer		NOT NULL REFERENCES event(id),
  value			float		NOT NULL,
  CONSTRAINT metric_to_event UNIQUE(metric_type_id, event_id)
);
