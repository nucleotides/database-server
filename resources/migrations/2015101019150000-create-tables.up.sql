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
CREATE MATERIALIZED VIEW benchmark_instance AS
SELECT
md5(benchmark_type.id || '-' || data_record.id || '-' || image_instance_task.id) AS id,
GREATEST(benchmark_type.created_at,
	 data_record.created_at,
	 image_type.created_at,
	 image_instance.created_at,
	 image_instance_task.created_at) AS created_at,
benchmark_type.id       AS benchmark_type_id,
data_record.id          AS data_record_id,
image_type.id           AS product_image_type_id,
image_instance.id       AS product_image_instance_id,
image_instance_task.id  AS product_image_task_id
FROM benchmark_type
LEFT JOIN benchmark_data      ON benchmark_type.id = benchmark_data.benchmark_type_id
LEFT JOIN data_record         ON benchmark_data.data_set_id = data_record.data_set_id
LEFT JOIN image_type          ON benchmark_type.product_image_type_id = image_type.id
LEFT JOIN image_instance      ON image_type.id = image_instance.image_type_id
LEFT JOIN image_instance_task ON image_instance.id = image_instance_task.image_instance_id
WHERE benchmark_type.active    = TRUE
AND benchmark_data.active      = TRUE
AND data_record.active         = TRUE
AND image_instance.active      = TRUE
AND image_instance_task.active = TRUE
ORDER BY benchmark_type_id         ASC,
         data_record_id            ASC,
         product_image_instance_id ASC,
         product_image_task_id     ASC,
         evaluation_image_type_id  ASC
--;;
CREATE UNIQUE INDEX primary_key  ON benchmark_instance (id);
--;;
CREATE INDEX benchmark_type_idx  ON benchmark_instance (benchmark_type_id);
--;;
CREATE INDEX data_record_id_idx  ON benchmark_instance (data_record_id);
--;;
CREATE INDEX product_image_type_id_idx  ON benchmark_instance (product_image_type_id);
--;;
CREATE INDEX product_image_instance_id_idx  ON benchmark_instance (product_image_instance_id);
--;;
CREATE INDEX product_image_instance_task_id_idx  ON benchmark_instance (product_image_task_id);
