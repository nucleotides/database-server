WITH event_ AS (
	INSERT INTO event (task_id, success)
	VALUES (2, true)
	RETURNING event_id
),
files_ AS (
	SELECT create_file_instance('f6b8e', 'container_log', 's3://log_file') AS file_instance_id
),
efi_ AS (
	INSERT INTO event_file_instance (file_instance_id, event_id)
	SELECT * FROM files_ CROSS JOIN event_
)
INSERT INTO metric_instance (metric_type_id, value, event_id)
VALUES ((SELECT metric_type_id FROM metric_type WHERE name = 'ng50'), 20000, (SELECT event_id FROM event_)),
       ((SELECT metric_type_id FROM metric_type WHERE name = 'lg50'), 10,    (SELECT event_id FROM event_));
