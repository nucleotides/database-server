WITH event_ AS (
	INSERT INTO event (task_id, success)
	VALUES (2, true)
	RETURNING id
),
files_ AS (
	INSERT INTO file_instance (file_type_id, sha256, url)
	VALUES ((SELECT id FROM file_type WHERE name = 'log'), 'f6b8e', 's3://log_file')
	RETURNING id
),
efi_ AS (
  INSERT INTO event_file_instance (file_instance_id, event_id)
  SELECT * FROM files_ CROSS JOIN event_

)
INSERT INTO metric_instance (metric_type_id, value, event_id)
VALUES ((SELECT id FROM metric_type WHERE name = 'ng50'), 20000, (SELECT id FROM event_)),
       ((SELECT id FROM metric_type WHERE name = 'lg50'), 10,    (SELECT id FROM event_));
