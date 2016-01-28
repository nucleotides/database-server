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
