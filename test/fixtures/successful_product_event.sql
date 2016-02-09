WITH event_ AS (
	INSERT INTO event (task_id, success)
	VALUES (1, true)
	RETURNING id
),
files_ AS (
	INSERT INTO file_instance (file_type_id, sha256, url)
	VALUES ((SELECT id FROM file_type WHERE name = 'log'), '66b8d', 's3://log_file'),
	       ((SELECT id FROM file_type WHERE name = 'contig_fasta'), 'f7455', 's3://contigs')
	RETURNING id
)
INSERT INTO event_file_instance (file_instance_id, event_id)
SELECT * FROM files_ CROSS JOIN event_
