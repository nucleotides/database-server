--;;
--;; Metric types
--;;
CREATE TABLE metric_type(
  id		serial		PRIMARY KEY,
  created_at	timestamp	DEFAULT current_timestamp,
  name		varchar(80)	UNIQUE NOT NULL,
  description	text 		NOT NULL
);
--;;
--;; Docker images
--;;
CREATE TABLE image_type(
  id		serial 		PRIMARY KEY,
  created_at	timestamp	DEFAULT current_timestamp,
  name          text            UNIQUE NOT NULL,
  description	text		NOT NULL
);
--;;
CREATE TABLE image_instance(
  id		serial 		PRIMARY KEY,
  created_at	timestamp	DEFAULT current_timestamp,
  image_type_id	integer		NOT NULL REFERENCES image_type(id),
  name		text	        NOT NULL,
  sha256	text 		NOT NULL,
  active	bool 		NOT NULL,
  CONSTRAINT image_instance_idx UNIQUE(image_type_id, name, sha256)
);
--;;
CREATE TABLE image_instance_task(
  id			serial 		PRIMARY KEY,
  created_at		timestamp	DEFAULT current_timestamp,
  image_instance_id	integer		NOT NULL REFERENCES image_instance(id),
  task			text 		NOT NULL,
  active		bool 		NOT NULL,
  CONSTRAINT image_instance_task_idx UNIQUE(image_instance_id, task)
);
--;;
--;; Data sets
--;;
CREATE TABLE data_set(
  id		serial 		PRIMARY KEY,
  created_at	timestamp	NOT NULL DEFAULT current_timestamp,
  name		text		UNIQUE NOT NULL,
  description	text		NOT NULL,
  active	bool 		NOT NULL
);
--;;
CREATE TABLE data_record(
  id		serial		PRIMARY KEY,
  created_at	timestamp	NOT NULL DEFAULT current_timestamp,
  data_set_id	integer		NOT NULL REFERENCES data_set(id),
  entry_id	integer         NOT NULL,
  replicate	integer 	NOT NULL,
  reads		integer		NOT NULL,
  input_url	text 		NOT NULL,
  reference_url	text 		NOT NULL,
  input_md5	text 		NOT NULL,
  reference_md5	text 		NOT NULL,
  active	bool 		NOT NULL,
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
  active			bool 		NOT NULL
);
--;;
CREATE TABLE benchmark_data(
  id			serial		PRIMARY KEY,
  created_at		timestamp	NOT NULL DEFAULT current_timestamp,
  data_set_id		integer		NOT NULL REFERENCES data_set(id),
  benchmark_type_id	integer		NOT NULL REFERENCES benchmark_type(id),
  active		bool 		NOT NULL,
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
