-- name: save-input-data-source<!
-- Creates a new input data source entry
INSERT INTO input_data_source (name, description, source_type_id)
SELECT :name, :description, (SELECT id FROM source_type WHERE name = :source_type)
WHERE NOT EXISTS (SELECT 1 FROM input_data_source WHERE name = :name);

-- name: save-input-data-source-file<!
-- Creates link between input_data_source and reference file_instance
WITH _existing_file AS (
  SELECT id FROM file_instance WHERE sha256 = :sha256
),
_new_file AS (
  INSERT INTO file_instance (file_type_id, sha256, url)
  SELECT (SELECT id FROM file_type WHERE name = :file_type), :sha256, :url
  WHERE NOT EXISTS (SELECT 1 FROM _existing_file)
  RETURNING id
),
_file AS (
  SELECT * FROM _existing_file
  UNION ALL
  SELECT * FROM _new_file
),
_input_data_source AS (
  SELECT * FROM input_data_source WHERE name = :source_name
)
INSERT INTO input_data_source_reference_file (input_data_source_id, file_instance_id)
SELECT (SELECT id FROM _input_data_source), (SELECT id FROM _file)
WHERE NOT EXISTS (
  SELECT 1
  FROM input_data_source_reference_file
  WHERE input_data_source_id = (SELECT id FROM _input_data_source)
  AND file_instance_id = (SELECT id FROM _file)
)


-- name: save-file-type<!
-- Creates a new data type entry
INSERT INTO file_type (name, description)
SELECT :name, :description
WHERE NOT EXISTS (SELECT 1 FROM file_type WHERE name = :name);

-- name: save-image-type<!
-- Creates a new Docker image type entry if not already exists
INSERT INTO image_type (name, description)
SELECT :name, :description
WHERE NOT EXISTS (SELECT 1 FROM image_type WHERE image_type.name = :name);

-- name: save-image-instance<!
-- Creates a new Docker image instance entry
WITH _type AS (
	SELECT id FROM image_type WHERE name = :image_type
)
INSERT INTO image_instance (image_type_id, name, sha256)
SELECT (SELECT id FROM _type), :name, :sha256
WHERE NOT EXISTS (
	SELECT 1 FROM image_instance
	WHERE image_type_id = (SELECT id FROM _type)
	AND name            = :name
	AND sha256          = :sha256);

-- name: save-image-task<!
-- Creates a new image task entry
WITH _instance AS (
	SELECT id FROM image_instance WHERE name = :name AND sha256 = :sha256
)
INSERT INTO image_instance_task (image_instance_id, task)
SELECT (SELECT id FROM _instance), :task
WHERE NOT EXISTS (
	SELECT 1 FROM image_instance_task
	WHERE image_instance_id = (SELECT id FROM _instance)
	AND task = :task
);

-- name: save-data-set<!
-- Creates a new data type entry
INSERT INTO data_set (name, description)
SELECT :name, :description
WHERE NOT EXISTS (SELECT 1 FROM data_set WHERE name = :name);

-- name: save-data-record<!
-- Creates a new data instance entry
WITH _dset AS (
	SELECT id FROM data_set WHERE name = :name
)
INSERT INTO data_record (
	data_set_id,
	entry_id,
	replicate,
	reads,
	input_url,
	reference_url,
	input_md5,
	reference_md5)
SELECT (SELECT id FROM _dset),
	:entry_id,
	:replicate,
	:reads,
	:input_url,
	:reference_url,
	:input_md5,
	:reference_md5
WHERE NOT EXISTS (
	SELECT 1 FROM data_record
	WHERE data_set_id = (SELECT id FROM _dset)
	AND entry_id      = :entry_id
	AND replicate     = :replicate);

-- name: save-benchmark-type<!
-- Creates a new benchmark type entry
WITH _product_image AS (
	SELECT id FROM image_type WHERE name = :product_image_type
),
_eval_image AS (
	SELECT id FROM image_type WHERE name = :evaluation_image_type
),
_dset AS (
	SELECT id FROM data_set WHERE name = :data_set_name
),
_existing_benchmark AS (
	SELECT id
	FROM benchmark_type
	WHERE name                    = :name
	AND product_image_type_id     = (SELECT id FROM _product_image)
	AND evaluation_image_type_id  = (SELECT id FROM _eval_image)
),
_inserted_benchmark AS (
	INSERT INTO benchmark_type (name, product_image_type_id, evaluation_image_type_id)
	SELECT :name, (SELECT id FROM _product_image), (SELECT id FROM _eval_image)
	WHERE NOT EXISTS (SELECT id FROM _existing_benchmark)
	RETURNING id
),
_benchmark AS (
	SELECT id FROM _existing_benchmark
	UNION ALL
	SELECT id FROM _inserted_benchmark
)
INSERT INTO benchmark_data (data_set_id, benchmark_type_id)
SELECT (SELECT id FROM _dset),
       (SELECT id FROM _benchmark)
WHERE NOT EXISTS (
	SELECT 1 FROM benchmark_data
	WHERE data_set_id     = (SELECT id FROM _dset)
	AND benchmark_type_id = (SELECT id FROM _benchmark))


-- name: populate-benchmark-instance!
-- Populates benchmark instance table with combinations of data record and image task
INSERT INTO benchmark_instance(
	benchmark_type_id,
	data_record_id,
	product_image_instance_task_id)
SELECT
benchmark_type.id,
data_record.id,
image_instance_task.id
FROM benchmark_type
LEFT JOIN benchmark_data      ON benchmark_type.id = benchmark_data.benchmark_type_id
LEFT JOIN data_record         ON benchmark_data.data_set_id = data_record.data_set_id
LEFT JOIN image_type          ON benchmark_type.product_image_type_id = image_type.id
LEFT JOIN image_instance      ON image_type.id = image_instance.image_type_id
LEFT JOIN image_instance_task ON image_instance.id = image_instance_task.image_instance_id
WHERE NOT EXISTS(
	SELECT external_id FROM benchmark_instance WHERE benchmark_instance.external_id = external_id
);

-- name: populate-task!
-- Populates benchmark instance table with combinations of data record and image task
INSERT INTO task (benchmark_instance_id, image_instance_task_id, task_type)
	SELECT
	benchmark_instance.id   AS benchmark_instance_id,
	image_instance_task.id  AS image_instance_task_id,
	'evaluate'::task_type AS benchmark_task_type
	FROM benchmark_instance
	LEFT JOIN benchmark_type      ON benchmark_type_id = benchmark_instance.benchmark_type_id
	LEFT JOIN image_instance      ON benchmark_type.evaluation_image_type_id = image_instance.image_type_id
	LEFT JOIN image_instance_task ON image_instance.id = image_instance_task.image_instance_id
UNION
	SELECT
	benchmark_instance.id	 AS benchmark_instance_id,
	benchmark_instance.product_image_instance_task_id AS image_instance_task_id,
	'produce'::task_type AS type
	FROM benchmark_instance
EXCEPT
	SELECT
	benchmark_instance_id,
	image_instance_task_id,
	task_type
	FROM task

-- name: save-metric-type<!
-- Creates a new data type entry
INSERT INTO metric_type (name, description)
SELECT :name, :description
WHERE NOT EXISTS (SELECT 1 FROM metric_type WHERE name = :name);
