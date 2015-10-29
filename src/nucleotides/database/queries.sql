-- name: save-image-type<!
-- Creates a new Docker image type table entry
INSERT INTO image_type (name, description)
VALUES (:name, :description);

-- name: save-image-task<!
-- Creates a new image task entry
INSERT INTO image_task (image_type_id, name, task, sha256, active)
VALUES (:image_type_id, :name, :task, :sha256, :active);

-- name: save-data-type<!
-- Creates a new data type entry
INSERT INTO data_type (name, library, type, description)
VALUES (:name, :library, :type, :description);
