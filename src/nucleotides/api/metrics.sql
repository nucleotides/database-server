-- name: create-metric-instance<!
-- Create a new metric instance
INSERT INTO metric_instance (metric_type_id, event_id, value)
VALUES ((SELECT metric_type_id FROM metric_type WHERE name = :name LIMIT 1), :id, :value::float)


-- name: metrics-by-event-id
-- Get metrics by a given event ID
SELECT
metric_type.name,
metric_instance.value
FROM metric_instance
LEFT JOIN metric_type USING (metric_type_id)
WHERE metric_instance.event_id = :id::int

-- name: all-metric-types
-- Get list of all available metric types
SELECT name FROM metric_type
