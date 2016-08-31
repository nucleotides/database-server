WITH event_ AS (
	INSERT INTO event (task_id, success)
	VALUES (2, false)
	RETURNING id
),
files_ AS (
	SELECT create_file_instance('1638e', 'log', 's3://log_file') AS id
)
INSERT INTO event_file_instance (file_instance_id, event_id)
SELECT * FROM files_ CROSS JOIN event_
