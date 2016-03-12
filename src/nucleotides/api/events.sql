-- name: create-event<!
-- Create a new event
INSERT INTO event (task_id, success)
VALUES (:task::integer, :success::boolean)

-- name: get-event
-- Get an event by its ID
SELECT * FROM event WHERE id = :id::int
