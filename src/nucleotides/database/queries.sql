-- name: save-image-type<!
-- Creates a new Docker image type entry if not already exists
INSERT INTO image_type (name, description)
SELECT :name, :description
WHERE NOT EXISTS (SELECT 1 FROM image_type WHERE image_type.name = :name);

-- name: save-image-instance<!
-- Creates a new Docker image instance entry
INSERT INTO image_instance (image_type_id, name, sha256, active)
VALUES ((SELECT id FROM image_type WHERE name = :image_type),
	:name, :sha256, true);

-- name: save-image-task<!
-- Creates a new image task entry
INSERT INTO image_instance_task (image_instance_id, task, active)
VALUES ((SELECT id FROM image_instance WHERE name = :name AND sha256 = :sha256),
	:task, true);

-- name: save-data-set<!
-- Creates a new data type entry
INSERT INTO data_set (name, description, active)
VALUES (:name, :description, true);

-- name: save-metric-type<!
-- Creates a new data type entry
INSERT INTO metric_type (name, description)
VALUES (:name, :description);

-- name: save-data-record<!
-- Creates a new data instance entry
INSERT INTO data_record (
	data_set_id,
	entry_id,
	replicate,
	reads,
	input_url,
	reference_url,
	input_md5,
	reference_md5,
	active)
VALUES ((SELECT id FROM data_set WHERE name = :name),
	:entry_id,
	:replicate,
	:reads,
	:input_url,
	:reference_url,
	:input_md5,
	:reference_md5,
        true);

-- name: save-benchmark-type<!
-- Creates a new benchmark type entry
WITH benchmark AS (
  INSERT INTO benchmark_type (name, product_image_type_id, evaluation_image_type_id, active)
  VALUES (
   :name,
   (SELECT id FROM image_type WHERE name = :product_image_type),
   (SELECT id FROM image_type WHERE name = :evaluation_image_type),
   true)
   RETURNING id
)
INSERT INTO benchmark_data (data_set_id, benchmark_type_id, active)
VALUES((SELECT id FROM data_set WHERE name = :data_set_name),
       (SELECT id FROM benchmark),
       true)

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
