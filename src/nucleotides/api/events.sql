-- name: create-benchmark-event<!
-- Create a new benchmark event
INSERT INTO benchmark_event (
	benchmark_instance_id,
	benchmark_file,
	log_file,
	event_type,
	success)
VALUES (:id,
	:benchmark_file,
	:log_file,
	:event_type::benchmark_event_type,
	:success::boolean)

-- name: create-metric-instance<!
-- Create a new metric instance
INSERT INTO metric_instance (metric_type_id, benchmark_event_id, value)
VALUES ((SELECT id FROM metric_type WHERE name = :name LIMIT 1), :id, :value::float)
