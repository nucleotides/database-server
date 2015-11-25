-- name: benchmarks
-- Get all benchmark entries
SELECT * FROM benchmark_instance_status;

-- name: benchmarks-by-product
-- Get all benchmark entries by product status
SELECT * FROM benchmark_instance_status
WHERE product = :product::boolean;

-- name: benchmarks-by-eval
-- Get all benchmark entries by evaluation status
SELECT * FROM benchmark_instance_status
WHERE evaluation = :evaluation::boolean;

-- name: benchmark-by-id
-- Get a benchmark entry by ID
SELECT
id, image_task, image_name, image_sha256, input_url, input_md5, product_url,
evaluation_id IS NOT NULL AS evaluation,
product_id    IS NOT NULL AS product
FROM benchmark_instance_status WHERE id = :id
LIMIT 1;

-- name: metrics-by-benchmark-id
-- Get metrics by a given benchmark ID
SELECT
mt.name,
mi.value
FROM benchmark_instance_status AS bis
LEFT JOIN metric_instance      AS mi ON mi.benchmark_event_id = bis.evaluation_id
LEFT JOIN metric_type          AS mt ON mi.metric_type_id = mt.id
WHERE bis.id = :id;

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
