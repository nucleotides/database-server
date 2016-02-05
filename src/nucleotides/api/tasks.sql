-- name: task-by-id
-- Look up a single task
SELECT *
FROM task_expanded_fields AS task
WHERE task.id = :id::int

-- name: incomplete-tasks
-- Get all incomplete tasks
WITH incomplete_task AS (
  SELECT task.*
  FROM task
  LEFT JOIN event ON event.task_id = task.id
  WHERE event.task_id IS NULL
),
incomplete_produce_task AS (
  SELECT *
  FROM incomplete_task
  WHERE incomplete_task.task_type = 'produce'
),
complete_produce_task AS (
  SELECT *
  FROM task
  LEFT JOIN event ON event.task_id = task.id
  WHERE task.task_type = 'produce'
  AND event.task_id IS NOT NULL
),
incomplete_evaluate_task AS (
  SELECT
  incomplete_task.*
  FROM complete_produce_task
  LEFT JOIN benchmark_instance ON benchmark_instance.id = complete_produce_task.benchmark_instance_id
  LEFT JOIN incomplete_task ON incomplete_task.benchmark_instance_id = benchmark_instance.id
  WHERE incomplete_task.task_type = 'evaluate'
)
SELECT * FROM incomplete_produce_task
UNION ALL
SELECT * FROM incomplete_evaluate_task
