WITH event_ AS (
	INSERT INTO event (task_id, success)
	VALUES (1, false)
	RETURNING id
),
files_ AS (
	INSERT INTO file_instance (file_type_id, sha256, url)
	VALUES ((SELECT id FROM file_type WHERE name = 'log'), '42ae5', 's3://log_file')
	RETURNING id
)
INSERT INTO event_file_instances (file_instance_id, event_id)
SELECT * FROM files_ CROSS JOIN event_
