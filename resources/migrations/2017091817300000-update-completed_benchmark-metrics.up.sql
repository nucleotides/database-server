-- Drop this view first to then drop dependent views
DROP VIEW completed_benchmark_metrics;

-- No longer going to base the completed_benchmark_metrics table off of this view
DROP VIEW image_task_benchmarking_state;


--
-- View of numbers of tasks per benchmark instance by benchmark type
--
-- The numbers of tasks is always going to be 1 (the produce task) plus however
-- many evaluation tasks there are.
--
  CREATE MATERIALIZED VIEW tasks_per_benchmark_instance_by_benchmark_type AS
  SELECT benchmark_type_id,
         (COUNT(image_task_id) + 1) AS n_tasks
    FROM benchmark_type
    JOIN image_expanded_fields ON benchmark_type.evaluation_image_type_id = image_expanded_fields.image_type_id
GROUP BY benchmark_type_id;
--
CREATE UNIQUE INDEX ON tasks_per_benchmark_instance_by_benchmark_type (benchmark_type_id);

--
-- View of the state of each benchmark instance
--
CREATE VIEW benchmark_instance_state AS
     SELECT benchmark_instance_id,
            COALESCE(bool_and(event.success), FALSE) AS instance_successful,
            COUNT(event_id) = n_tasks                AS instance_finished
       FROM benchmark_instance
       JOIN task                                           USING (benchmark_instance_id)
       JOIN tasks_per_benchmark_instance_by_benchmark_type USING (benchmark_type_id)
  LEFT JOIN events_prioritised_by_successful AS event USING (task_id)
   GROUP BY benchmark_instance_id, n_tasks;

--
-- Simpler view of all benchmarking metrics, only requiring each individual
-- benchmark instance has been completed, rather than all tasks for a given image
-- task be completed.
--
CREATE VIEW completed_benchmark_metrics AS
     SELECT external_id                        AS benchmark_id,
            benchmark_type.name                AS benchmark_type_name,
     	    input_file.sha256                  AS input_file_id,
     	    image_type_name                    AS image_type,
     	    image_instance_name                AS image_name,
     	    image_version_name                 AS image_version,
     	    image_task_name                    AS image_task,
     	    input_file.platform,
     	    input_file.protocol,
     	    input_file.material,
     	    input_file.extraction_method,
     	    input_file.run_mode,
     	    input_file.biological_source_type,
     	    input_file.biological_source_name,
     	    input_file.input_file_set_name,
     	    metric_type.name                   AS variable,
     	    metric_instance.value
       FROM benchmark_instance_state        AS state
       JOIN benchmark_instance                             USING (benchmark_instance_id)
       JOIN benchmark_type                                 USING (benchmark_type_id)
       JOIN input_data_file_expanded_fields AS input_file  USING (input_data_file_id)
       JOIN image_expanded_fields           AS image       ON benchmark_instance.product_image_task_id = image.image_task_id
       JOIN task                                           USING (benchmark_instance_id)
       JOIN events_prioritised_by_successful               USING (task_id)
       JOIN metric_instance                                USING (event_id)
       JOIN metric_type                                    USING (metric_type_id)
      WHERE state.instance_successful = true
        AND state.instance_finished   = true;
