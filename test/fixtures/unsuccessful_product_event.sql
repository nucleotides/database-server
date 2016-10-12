WITH event_ AS (
	INSERT INTO event (task_id, success)
	VALUES (1, false)
	RETURNING event_id
),
files_ AS (
	SELECT create_file_instance('42ae5', 'container_log', 's3://log_file')
)
INSERT INTO event_file_instance (file_instance_id, event_id)
SELECT * FROM files_ CROSS JOIN event_
