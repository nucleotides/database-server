WITH event_ AS (
	INSERT INTO event (task_id, success)
	VALUES (1, true)
	RETURNING event_id
),
files_ AS (
	SELECT create_file_instance('aef563', 'container_log', 's3://log_file')
	UNION ALL
	SELECT create_file_instance('7830af', 'container_runtime_metrics', 's3://metrics')
	UNION ALL
	SELECT create_file_instance('3df123', 'contig_fasta', 's3://contigs')
)
INSERT INTO event_file_instance (file_instance_id, event_id)
SELECT * FROM files_ CROSS JOIN event_
