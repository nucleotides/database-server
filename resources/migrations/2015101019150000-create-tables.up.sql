CREATE TABLE image_type(
  id		serial 		PRIMARY KEY,
  added		timestamp	DEFAULT current_timestamp,
  description	text		NOT NULL
);
--;;
CREATE TABLE image_task(
  id		serial 		PRIMARY KEY,
  added		timestamp	DEFAULT current_timestamp,
  image_type_id	integer		NOT NULL REFERENCES image_type(id),
  name		text	        NOT NULL,
  task		text 		NOT NULL,
  sha256	integer 	NOT NULL,
  active	bool 		NOT NULL,
  UNIQUE(image_type_id, name, task)
);
--;;
CREATE TABLE data_type(
  id		serial 		PRIMARY KEY,
  added		timestamp	NOT NULL DEFAULT current_timestamp,
  description	text		NOT NULL
);
--;;
CREATE TABLE data_instance(
  id		serial		PRIMARY KEY,
  added		timestamp	NOT NULL DEFAULT current_timestamp,
  data_type_id	integer		NOT NULL REFERENCES data_type(id),
  replicate	integer 	NOT NULL,
  input_url	text 		NOT NULL,
  reference_url	text 		NOT NULL,
  input_md5	integer 	NOT NULL,
  reference_md5	integer 	NOT NULL,
  UNIQUE(data_type_id, replicate)
);
--;;
CREATE TABLE benchmark_type(
  id		serial		PRIMARY KEY,
  added		timestamp	NOT NULL DEFAULT current_timestamp,
  data_type_id	integer		NOT NULL REFERENCES data_type(id),
  image_type_id	integer		NOT NULL REFERENCES image_type(id),
  UNIQUE(data_type_id, image_type_id)
);
--;;
CREATE TABLE benchmark_instance(
  id			serial		PRIMARY KEY,
  added			timestamp	DEFAULT current_timestamp,
  benchmark_type_id	integer		NOT NULL REFERENCES benchmark_type(id),
  image_task_id		integer		NOT NULL REFERENCES image_task(id),
  data_instance_id	integer         NOT NULL REFERENCES data_instance(id),
  UNIQUE(benchmark_type_id, image_task_id, data_instance_id)
);
--;;
CREATE TABLE benchmark_event_status(
  id			serial		PRIMARY KEY,
  added			timestamp	NOT NULL DEFAULT current_timestamp,
  name			varchar(80)	UNIQUE NOT NULL,
  description		text 		NOT NULL
);
--;;
CREATE TABLE benchmark_event(
  id				serial		PRIMARY KEY,
  added				timestamp	DEFAULT current_timestamp,
  benchmark_instance_id		integer		NOT NULL REFERENCES benchmark_instance(id),
  benchmark_event_status_id	integer		NOT NULL REFERENCES benchmark_event_statuse(id)
);
--;;
CREATE TABLE metric_type(
  id		serial		PRIMARY KEY,
  added		timestamp	DEFAULT current_timestamp,
  name		varchar(80)	UNIQUE NOT NULL,
  description	text 		NOT NULL
);
--;;
CREATE TABLE metric_instance(
  id			serial		PRIMARY KEY,
  added			timestamp	DEFAULT current_timestamp,
  metric_type_id	integer		NOT NULL REFERENCES metric_type(id),
  benchmark_event_id	integer		NOT NULL REFERENCES benchmark_event(id),
  value			float 		NOT NULL,
  UNIQUE(metric_type_id, benchmark_event_id)
);
