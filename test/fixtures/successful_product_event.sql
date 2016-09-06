WITH event_ AS (
	INSERT INTO event (task_id, success)
	VALUES (1, true)
	RETURNING id
),
files_ AS (
	SELECT create_file_instance('12def', 'container_runtime_metrics', 's3://metrics')
	UNION ALL
	SELECT create_file_instance('66b8d', 'container_log', 's3://log_file')
	UNION ALL
	SELECT create_file_instance('f7455', 'contig_fasta', 's3://contigs')
)
INSERT INTO event_file_instance (file_instance_id, event_id)
SELECT * FROM files_ CROSS JOIN event_
