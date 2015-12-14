INSERT INTO event (task_id, file_url, file_md5, log_file_url, success)
VALUES ((SELECT id FROM task WHERE task_type = 'produce'),
	's3://url', '123abc', 's3://url', 'true')
