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
	reference_md5)
VALUES ((SELECT id FROM data_set WHERE name = :name),
	:entry_id,
	:replicate,
	:reads,
	:input_url,
	:reference_url,
	:input_md5,
	:reference_md5);

-- name: save-benchmark-type<!
-- Creates a new benchmark type entry
INSERT INTO benchmark_type (data_set_id, image_type_id, name)
VALUES ((SELECT id FROM data_set  WHERE type = :data_set),
        (SELECT id FROM image_type WHERE name = :image_type),
	:name);
