-- name: all-file-types
-- Get list of all available metric types
SELECT name FROM file_type


-- name: create-event-file-instance<!
-- Create a new file_instance and event_file_instance reference
WITH _file AS (
  SELECT create_file_instance(:sha256, :type, :url) AS id
)
INSERT INTO event_file_instance (event_id, file_instance_id)
VALUES (:event_id, (SELECT id FROM _file))




-- name: get-event-file-instance
-- Get all file_instances associated with an event
SELECT
file_instance.url,
file_instance.sha256,
file_type.name AS type
FROM event
LEFT JOIN event_file_instance ON event_file_instance.event_id = event.id
LEFT JOIN file_instance       ON file_instance.id = event_file_instance.file_instance_id
LEFT JOIN file_type           ON file_type.id = file_instance.file_type_id
WHERE event.id = :id::int
