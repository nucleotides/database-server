-- name: save-image-type<!
-- Creates a new Docker image type entry
INSERT INTO image_type (name, description)
VALUES (:name, :description);

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
