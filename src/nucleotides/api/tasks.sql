-- name: task-by-id
-- Look up a single task
SELECT *
FROM task_expanded_fields
WHERE task_id = :id::int

-- name: events-by-task-id
-- Get all events for a given task
SELECT event_id FROM event WHERE task_id = :id::int

-- name: incomplete-tasks
-- Get all incomplete tasks
WITH incomplete_task AS (
  SELECT *
  FROM task_expanded_fields
  WHERE complete = FALSE
),
incomplete_produce_task AS (
  SELECT *
  FROM task_expanded_fields
  WHERE complete = FALSE
  AND task_type = 'produce'
),
complete_produce_task AS (
  SELECT *
  FROM task_expanded_fields
  WHERE complete = TRUE
  AND task_type = 'produce'
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
