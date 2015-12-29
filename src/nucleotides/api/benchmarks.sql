-- name: benchmark-by-id
-- Get a benchmark entry by ID
WITH _benchmark AS (
	SELECT
	GREATEST(
		benchmark_instance.created_at,
		image_instance.created_at,
		image_instance_task.created_at) AS created_at,
	benchmark_instance.id AS benchmark_instance_id,
	benchmark_instance.external_id,
	image_instance_task.task       AS image_task,
	image_instance.name            AS image_name,
	image_instance.sha256          AS image_sha256,
	benchmark_type.name
	FROM benchmark_instance
	LEFT JOIN image_instance_task	ON image_instance_task.id = benchmark_instance.product_image_instance_task_id
	LEFT JOIN image_instance	ON image_instance.id      = image_instance_task.image_instance_id
	LEFT JOIN benchmark_type	ON benchmark_type.id      = benchmark_instance.benchmark_type_id
	WHERE external_id = :id
	LIMIT 1
),
_product AS (
	SELECT
	task.benchmark_instance_id,
	event.file_url			AS product_file_url,
	event.file_md5			AS product_file_md5,
	event.log_file_url		AS product_log_url
	FROM task
	RIGHT JOIN _benchmark 	USING (benchmark_instance_id)
	LEFT JOIN event 	ON event.task_id = task.id
	WHERE task.task_type = 'produce'
	AND event.success = TRUE
	LIMIT 1
)
SELECT
*
FROM _benchmark
LEFT JOIN _product USING (benchmark_instance_id)

-- name: benchmark-evaluations-by-id
-- Get evaluations for a benchmark entry by ID
SELECT DISTINCT ON (task.id)
event.file_url		AS evaluate_file_url,
event.file_md5		AS evaluate_file_md5,
event.log_file_url	AS evaluate_log_url
FROM benchmark_instance
LEFT JOIN task		ON task.benchmark_instance_id = benchmark_instance.id
LEFT JOIN event	ON event.task_id = task.id
WHERE benchmark_instance.external_id = :id
AND task.task_type = 'evaluate'
AND event.success = TRUE
