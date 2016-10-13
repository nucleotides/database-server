-- name: all-file-types
-- Get list of all available metric types
SELECT name FROM file_type

-- name: create-event-file-instance<!
-- Create a new file_instance and event_file_instance reference
INSERT INTO event_file_instance (event_id, file_instance_id)
VALUES (:event_id, (SELECT create_file_instance(:sha256, :type, :url)));

-- name: get-event-file-instance
-- Get all file_instances associated with an event
SELECT
url,
sha256,
file_type.name AS type
FROM event_file_instance
INNER JOIN file_instance  USING (file_instance_id)
INNER JOIN file_type      USING (file_type_id)
WHERE event_id = :id::int
