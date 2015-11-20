CREATE TABLE image_type(
  id		serial 		PRIMARY KEY,
  created_at	timestamp	DEFAULT current_timestamp,
  name          text            UNIQUE NOT NULL,
  description	text		NOT NULL
);
--;;
CREATE TABLE image_task(
  id		serial 		PRIMARY KEY,
  created_at	timestamp	DEFAULT current_timestamp,
  image_type_id	integer		NOT NULL REFERENCES image_type(id),
  name		text	        NOT NULL,
  task		text 		NOT NULL,
  sha256	text 		NOT NULL,
  active	bool 		NOT NULL,
  CONSTRAINT image UNIQUE(image_type_id, name, task, sha256)
);
--;;
CREATE TABLE data_type(
  id		serial 		PRIMARY KEY,
  created_at	timestamp	NOT NULL DEFAULT current_timestamp,
  name		text		UNIQUE NOT NULL,
  library	text		NOT NULL,
  description	text		NOT NULL,
  type		text		NOT NULL
);
--;;
CREATE TABLE data_instance(
  id		serial		PRIMARY KEY,
  created_at	timestamp	NOT NULL DEFAULT current_timestamp,
  data_type_id	integer		NOT NULL REFERENCES data_type(id),
  entry_id	integer         NOT NULL,
  replicate	integer 	NOT NULL,
  reads		integer		NOT NULL,
  input_url	text 		NOT NULL,
  reference_url	text 		NOT NULL,
  input_md5	text 		NOT NULL,
  reference_md5	text 		NOT NULL,
  CONSTRAINT data_replicates UNIQUE(data_type_id, entry_id, replicate)
);
--;;
CREATE TABLE benchmark_type(
  id		serial		PRIMARY KEY,
  created_at	timestamp	NOT NULL DEFAULT current_timestamp,
  name		text		UNIQUE NOT NULL,
  data_type_id	integer		NOT NULL REFERENCES data_type(id),
  image_type_id	integer		NOT NULL REFERENCES image_type(id),
  CONSTRAINT data_image UNIQUE(data_type_id, image_type_id)
);
--;;
CREATE MATERIALIZED VIEW benchmark_instance AS
SELECT
  md5(bt.id || '-' || di.id || '-' || it.id) AS id,
  bt.id AS benchmark_type_id,
  di.id AS data_instance_id,
  it.id AS image_task_id,
  bt.data_type_id,
  bt.image_type_id
FROM benchmark_type     AS bt
LEFT JOIN data_instance AS di ON bt.data_type_id  = di.data_type_id
LEFT JOIN image_task    AS it ON it.image_type_id = bt.image_type_id;
--;;
CREATE UNIQUE INDEX primary_key   ON benchmark_instance (id);
--;;
CREATE INDEX data_instance_id_idx ON benchmark_instance (data_instance_id);
--;;
CREATE INDEX image_task_id_idx    ON benchmark_instance (image_task_id);
--;;
CREATE TYPE benchmark_event_type AS ENUM ('product', 'evaluation');
--;;
CREATE TABLE benchmark_event(
  id				serial			PRIMARY KEY,
  created_at			timestamp		DEFAULT current_timestamp,
  benchmark_instance_id		text			NOT NULL,
  benchmark_file		text			NOT NULL,
  log_file			text			NOT NULL,
  event_type			benchmark_event_type	NOT NULL,
  success			boolean			NOT NULL
);
--;;
CREATE INDEX benchmark_instance_id_idx ON benchmark_event (benchmark_instance_id);
--;;
CREATE VIEW benchmark_instance_status AS SELECT
bi.id  AS id,
task   AS image_task,
name   AS image_name,
sha256 AS image_sha256,
input_url,
input_md5,
( SELECT
  be.created_at
  FROM benchmark_event AS be
  WHERE be.benchmark_instance_id = bi.id
  AND be.success = true
  AND be.event_type = 'product'
  LIMIT 1) IS NOT NULL AS product,
( SELECT
  be.created_at
  FROM benchmark_event AS be
  WHERE be.benchmark_instance_id = bi.id
  AND be.success = true
  AND be.event_type = 'evaluation'
  LIMIT 1) IS NOT NULL AS evaluation
FROM benchmark_instance   AS bi
LEFT JOIN image_task      AS it ON bi.image_task_id    = it.id
LEFT JOIN data_instance   AS di ON bi.data_instance_id = di.id;
--;;
CREATE TABLE metric_type(
  id		serial		PRIMARY KEY,
  created_at	timestamp	DEFAULT current_timestamp,
  name		varchar(80)	UNIQUE NOT NULL,
  description	text 		NOT NULL
);
--;;
CREATE TABLE metric_instance(
  id			serial		PRIMARY KEY,
  created_at		timestamp	DEFAULT current_timestamp,
  metric_type_id	integer		NOT NULL REFERENCES metric_type(id),
  benchmark_event_id	integer		NOT NULL REFERENCES benchmark_event(id),
  value			float 		NOT NULL,
  CONSTRAINT metric_to_event UNIQUE(metric_type_id, benchmark_event_id)
);
