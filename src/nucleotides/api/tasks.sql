-- name: incomplete-tasks
-- Get all incomplete tasks
SELECT
task.id,
task.task_type           AS task_type,
image_instance_task.task AS image_task,
image_instance.sha256    AS image_sha256,
image_instance.name      AS image_name,
image_type.name          AS image_type,
data_record.input_md5,
data_record.input_url
FROM task
LEFT JOIN image_instance_task ON image_instance_task.id = task.image_instance_task_id
LEFT JOIN image_instance      ON image_instance.id      = image_instance_task.image_instance_id
LEFT JOIN image_type          ON image_type.id          = image_instance.image_type_id
LEFT JOIN benchmark_instance  ON benchmark_instance.id  = task.benchmark_instance_id
LEFT JOIN data_record         ON data_record.id         = benchmark_instance.data_record_id
WHERE task.task_type = 'produce'
