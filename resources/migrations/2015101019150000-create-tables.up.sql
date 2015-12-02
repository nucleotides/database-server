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
  data_set_id			integer		NOT NULL REFERENCES data_set(id),
  active			bool 		NOT NULL,
  CONSTRAINT data_image UNIQUE(data_set_id, product_image_type_id)
);
