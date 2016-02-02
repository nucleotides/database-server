-- name: benchmark-produce-files-by-id
-- Get all input produce files by benchmark-instance-id
SELECT
file_instance.sha256,
file_instance.url,
file_type.name AS type
FROM benchmark_instance
LEFT JOIN input_data_file    ON input_data_file.id = benchmark_instance.input_data_file_id
LEFT JOIN file_instance      ON file_instance.id = input_data_file.file_instance_id
LEFT JOIN file_type          ON file_type.id = file_instance.file_type_id
WHERE benchmark_instance.id = :id::int

-- name: benchmark-by-id
-- Get a benchmark entry by ID
SELECT
GREATEST(
	benchmark_instance.created_at,
	image_instance.created_at,
	image_instance_task.created_at) AS created_at,
benchmark_instance.external_id	AS id,
image_instance_task.task	AS image_task,
image_instance.name		AS image_name,
image_instance.sha256		AS image_sha256,
benchmark_type.name
FROM benchmark_instance
LEFT JOIN image_instance_task	ON image_instance_task.id = benchmark_instance.product_image_instance_task_id
LEFT JOIN image_instance	ON image_instance.id      = image_instance_task.image_instance_id
LEFT JOIN benchmark_type	ON benchmark_type.id      = benchmark_instance.benchmark_type_id
WHERE external_id = :id
LIMIT 1


-- name: benchmark-product-by-id
-- Get product for a benchmark entry by ID
SELECT
event.file_url		AS url,
event.file_md5		AS md5,
event.log_file_url	AS log
FROM event
LEFT JOIN task			ON event.task_id = task.id
LEFT JOIN benchmark_instance	ON benchmark_instance.id = task.benchmark_instance_id
WHERE task.task_type = 'produce'
AND event.success = TRUE
AND benchmark_instance.external_id = :id
LIMIT 1


-- name: benchmark-evaluations-by-id
-- Get evaluations for a benchmark entry by ID
SELECT DISTINCT ON (task.id)
event.file_url		AS url,
event.file_md5		AS md5,
event.log_file_url	AS log
FROM benchmark_instance
LEFT JOIN task		ON task.benchmark_instance_id = benchmark_instance.id
LEFT JOIN event	ON event.task_id = task.id
WHERE benchmark_instance.external_id = :id
AND task.task_type = 'evaluate'
AND event.success = TRUE


-- name: benchmark-metrics-by-id
-- Get metrics for a benchmark entry by ID
SELECT DISTINCT ON (metric_type.id)
metric_type.name,
metric_instance.value
FROM benchmark_instance
LEFT JOIN task			ON task.benchmark_instance_id = benchmark_instance.id
LEFT JOIN event			ON event.task_id = task.id
RIGHT JOIN metric_instance	ON metric_instance.event_id = event.id
LEFT JOIN metric_type		ON metric_type.id = metric_instance.metric_type_id
WHERE benchmark_instance.external_id = :id
AND event.success = TRUE
