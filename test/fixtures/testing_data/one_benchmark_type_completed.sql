INSERT INTO event (task_id, success)
     SELECT task_id, true
       FROM benchmark_instance
       JOIN task USING (benchmark_instance_id)
      WHERE benchmark_type_id = 1;

INSERT INTO metric_instance (event_id, metric_type_id, value)
     SELECT event_id,
            metric_type_id,
	    1e9 AS value
       FROM event
       JOIN task USING (task_id)
 CROSS JOIN metric_type
      WHERE task_type = 'produce'
        AND metric_type.name IN ('total_wall_clock_time_in_seconds', 'max_cpu_usage');

INSERT INTO metric_instance (event_id, metric_type_id, value)
     SELECT event_id,
            metric_type_id,
	    1e9 AS value
       FROM event
       JOIN task USING (task_id)
 CROSS JOIN metric_type
      WHERE task.image_task_id = 4
        AND metric_type.name = 'total_length_gt_0';

INSERT INTO file_instance (file_type_id, sha256, url)
     SELECT file_type_id,
            'contig_'::text || to_char(row_number() OVER (ORDER by task_id), '9') AS digest,
            'url' AS url
       FROM event
       JOIN task USING (task_id)
 CROSS JOIN file_type
      WHERE file_type.name = 'contig_fasta'
        AND task_type = 'produce';

INSERT INTO event_file_instance (event_id, file_instance_id)
     SELECT event_id,
            file_instance_id
       FROM (SELECT event_id,
                    row_number() OVER (ORDER by event_id) AS tmp_id
               FROM event
               JOIN task USING (task_id)
              WHERE task_type = 'produce') AS e
       JOIN (SELECT file_instance_id,
                    row_number() OVER (ORDER by file_instance_id) AS tmp_id
	       FROM file_instance
               JOIN file_type USING (file_type_id)
              WHERE file_type.name = 'contig_fasta') AS f USING (tmp_id);
