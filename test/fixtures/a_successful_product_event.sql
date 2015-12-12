WITH task_ AS (SELECT id FROM task WHERE task_type = 'product')
INSERT INTO event (task_id, file_url, file_md5, log_file_url, success)
VALUES (task_.id, "s3://url", "123abc", "s3://url", "true")
