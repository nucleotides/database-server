-- name: save-image-type<!
-- Creates a new Docker image type table entry
INSERT INTO image_type (name, description)
VALUES (:name, :description);

-- name: save-image-task<!
-- Creates a new image task entry
INSERT INTO image_task (image_type_id, name, task, sha256, active)
VALUES ((SELECT id FROM image_type WHERE name = :image_type),
	:name, :task, :sha256, true);

-- name: save-data-type<!
-- Creates a new data type entry
INSERT INTO data_type (name, library, type, description)
VALUES (:name, :library, :type, :description);

-- name: save-data-instance<!
-- Creates a new data instance entry
INSERT INTO data_instance (
	data_type_id,
	entry_id,
	replicate,
	reads,
	input_url,
	reference_url,
	input_md5,
	reference_md5)
VALUES ((SELECT id FROM data_type WHERE type = :data_type),
	:entry_id,
	:replicate,
	:reads,
	:input_url,
	:reference_url,
	:input_md5,
	:reference_md5);

-- name: save-benchmark-type<!
-- Creates a new benchmark type entry
INSERT INTO benchmark_type (data_type_id, image_type_id, name)
VALUES ((SELECT id FROM data_type  WHERE type = :data_type),
        (SELECT id FROM image_type WHERE name = :image_type),
	:name);

-- name: benchmark-instances
-- Get all benchmark entries
SELECT
bi.id AS id, task, name, sha256, input_url as url, input_md5 as md5
FROM benchmark_instance AS bi
LEFT JOIN image_task    AS it ON bi.image_task_id    = it.id
LEFT JOIN data_instance AS di ON bi.data_instance_id = di.id;
