-- name: create-event<!
-- Create a new event
INSERT INTO event (task_id, file_url, file_md5, log_file_url, success)
VALUES (:task::integer, :file_url, :file_md5, :log_file_url, :success::boolean)

-- name: create-metric-instance<!
-- Create a new metric instance
INSERT INTO metric_instance (metric_type_id, benchmark_event_id, value)
VALUES ((SELECT id FROM metric_type WHERE name = :name LIMIT 1), :id, :value::float)

-- name: get-event
-- Get a metric by its ID
SELECT * FROM event WHERE id = :id::int
