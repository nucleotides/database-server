-- name: incomplete-tasks
-- Get all incomplete tasks
WITH successful_prod_event AS (
	SELECT DISTINCT ON (task.id)
	event.*,
	task.benchmark_instance_id
	FROM event
	LEFT JOIN task ON task.id = event.task_id
	WHERE event.success = TRUE
	AND task.task_type = 'produce'
),
successful_eval_event AS (
	SELECT DISTINCT ON (task.id)
	event.*,
	task.benchmark_instance_id
	FROM event
	LEFT JOIN task ON task.id = event.task_id
	WHERE event.success = TRUE
	AND task.task_type = 'evaluate'
),
task_ AS (
	SELECT
	task.id,
	task.task_type           AS task_type,
	image_instance_task.task AS image_task,
	image_instance.sha256    AS image_sha256,
	image_instance.name      AS image_name,
	image_type.name          AS image_type,
	task.benchmark_instance_id
	FROM task
	LEFT JOIN image_instance_task ON image_instance_task.id   = task.image_instance_task_id
	LEFT JOIN image_instance      ON image_instance.id        = image_instance_task.image_instance_id
	LEFT JOIN image_type          ON image_type.id            = image_instance.image_type_id
),
product_task AS (
	SELECT
	task_.id,
	task_.task_type,
	task_.image_task,
	task_.image_sha256,
	task_.image_name,
	task_.image_type,
	data_record.input_url,
	data_record.input_md5
	FROM task_
	LEFT JOIN benchmark_instance    ON benchmark_instance.id    = task_.benchmark_instance_id
	LEFT JOIN data_record           ON data_record.id           = benchmark_instance.data_record_id
	LEFT JOIN successful_prod_event ON successful_prod_event.task_id = task_.id
	WHERE task_.task_type = 'produce'
	AND successful_prod_event.id IS NULL
),
evaluate_task AS (
	SELECT
	task_.id,
	task_.task_type,
	task_.image_task,
	task_.image_sha256,
	task_.image_name,
	task_.image_type,
	successful_prod_event.file_url AS input_url,
	successful_prod_event.file_md5 AS input_md5
	FROM task_
	RIGHT JOIN successful_prod_event ON successful_prod_event.benchmark_instance_id = task_.benchmark_instance_id
	LEFT JOIN successful_eval_event ON successful_eval_event.task_id = task_.id
	WHERE task_.task_type = 'evaluate'
	AND successful_eval_event.id IS NULL
)
SELECT * FROM product_task
UNION
SELECT * FROM evaluate_task
