WITH event_ AS (
	INSERT INTO event (task_id, file_url, file_md5, log_file_url, success)
	VALUES ((SELECT id FROM task WHERE task_type = 'evaluate'),
		's3://url', '123abc', 's3://url', 'true') RETURNING id
)
INSERT INTO metric_instance (event_id, metric_type_id, value)
VALUES ((SELECT id FROM event_),
	(SELECT id FROM metric_type WHERE name = 'ng50'),
	5),
       ((SELECT id FROM event_),
	(SELECT id FROM metric_type WHERE name = 'lg50'),
	20000)
