-- name: task-by-id
-- Look up a single task
SELECT *
FROM task_expanded_fields AS task
WHERE task.id = :id::int

-- name: incomplete-tasks
-- Get all incomplete tasks
SELECT id FROM task WHERE task.task_type = 'produce'
