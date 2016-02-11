-- name: create-event<!
-- Create a new event
INSERT INTO event (task_id, success)
VALUES (:task::integer, :success::boolean)


-- name: create-event-file-instance<!
-- Create a new file_instance and event_file_instance reference
WITH file_ AS (
  INSERT INTO file_instance (file_type_id, sha256, url)
  VALUES ((SELECT id FROM file_type WHERE name = :type LIMIT 1), :sha256, :url)
  RETURNING id
)
INSERT INTO event_file_instance (event_id, file_instance_id)
VALUES (:event_id, (SELECT id FROM file_))


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


-- name: create-metric-instance<!
-- Create a new metric instance
INSERT INTO metric_instance (metric_type_id, event_id, value)
VALUES ((SELECT id FROM metric_type WHERE name = :name LIMIT 1), :id, :value::float)

-- name: get-event
-- Get a metric by its ID
SELECT * FROM event WHERE id = :id::int

-- name: metrics-by-event-id
-- Get metrics by a given event ID
SELECT
metric_type.name,
metric_instance.value
FROM metric_instance
LEFT JOIN metric_type ON metric_type.id = metric_instance.metric_type_id
WHERE metric_instance.event_id = :id::int
