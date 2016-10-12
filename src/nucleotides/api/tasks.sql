-- name: task-by-id
-- Look up a single task
SELECT *
FROM task_expanded_fields AS task
WHERE task_id = :id::int

-- name: events-by-task-id
-- Get all events for a given task
SELECT event_id FROM event WHERE task_id = :id::int

-- name: incomplete-tasks
-- Get all incomplete tasks
WITH successful_event AS (
  SELECT * FROM event WHERE event.success = TRUE
),
incomplete_task AS (
  SELECT task.*
  FROM task
  LEFT JOIN successful_event USING (task_id)
  WHERE successful_event.task_id IS NULL
),
incomplete_produce_task AS (
  SELECT *
  FROM incomplete_task
  WHERE incomplete_task.task_type = 'produce'
),
complete_produce_task AS (
  SELECT *
  FROM task
  LEFT JOIN successful_event USING (task_id)
  WHERE task.task_type = 'produce'
  AND successful_event.task_id IS NOT NULL
),
incomplete_evaluate_task AS (
  SELECT
  incomplete_task.*
  FROM complete_produce_task
  LEFT JOIN benchmark_instance USING (benchmark_instance_id)
  LEFT JOIN incomplete_task    USING (benchmark_instance_id)
  WHERE incomplete_task.task_type = 'evaluate'
)
SELECT * FROM incomplete_produce_task
UNION ALL
SELECT * FROM incomplete_evaluate_task
