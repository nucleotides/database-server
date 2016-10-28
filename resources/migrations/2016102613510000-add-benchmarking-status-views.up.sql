--;;
--;; Summary of all the tasks
--;;
CREATE VIEW task_summary AS
WITH task_ AS (
     SELECT COALESCE(task_type::text, 'all')                         AS task_type,
            COUNT(task_id)                                           AS n,
            COUNT(task_id) = COUNT(event_id)                         AS is_executed,
            COUNT(task_id) filter (where event.event_id IS NULL)     AS n_outstanding,
            COUNT(task_id) filter (where event.event_id IS NOT NULL) AS n_executed,
            COUNT(task_id) filter (where event.success = true)       AS n_successful,
            COUNT(task_id) filter (where event.success = false)      AS n_errorful,
            MAX(event.created_at)                                    AS date_of_most_recent
       FROM task
  LEFT JOIN events_prioritised_by_successful AS event USING (task_id)
   GROUP BY ROLLUP(task_type)
)
SELECT *,
       round(n_outstanding / n::numeric, 4) * 100 AS percent_outstanding,
       round(n_executed / n::numeric, 4) * 100    AS percent_executed,
       round(n_errorful / n::numeric, 4) * 100    AS percent_errorful,
       round(n_successful / n::numeric, 4) * 100  AS percent_successful
  FROM task_;
--;;
--;; Summary of all the benchmarks
--;;
CREATE VIEW benchmark_summary AS
WITH benchmark_ AS (
     SELECT COALESCE(benchmark_type.name, 'all')                 AS benchmark_type,
            COUNT(benchmark_type.name)                           AS n,
            COUNT(benchmark_type.name) - COUNT(event_id)         AS n_outstanding,
            COUNT(event_id)                                      AS n_executed,
            COUNT(event_id) filter (where event.success = false) AS n_errorful,
            COUNT(event_id) filter (where event.success = true)  AS n_successful,
            COUNT(benchmark_type.name) = COUNT(event_id)         AS is_executed,
            MAX(event.created_at)                                AS date_of_most_recent
       FROM benchmark_instance
       JOIN benchmark_type USING (benchmark_type_id)
 INNER JOIN task                                                USING (benchmark_instance_id)
  LEFT JOIN events_prioritised_by_successful  AS event          USING (task_id)
   GROUP BY ROLLUP(benchmark_type.name)
)
SELECT *,
       round(n_outstanding / n::numeric, 4) * 100 AS percent_outstanding,
       round(n_executed / n::numeric, 4) * 100    AS percent_executed,
       round(n_errorful / n::numeric, 4) * 100    AS percent_errorful,
       round(n_successful / n::numeric, 4) * 100  AS percent_successful
  FROM benchmark_;

--;;
--;; Summary of various important numbers across benchmarking
--;;
CREATE VIEW global_summary AS
SELECT
    (SELECT COUNT(1) FROM event_file_instance) AS n_files_generated,
    (SELECT COUNT(1) FROM metric_instance)     AS n_metrics_collected,
    round((SELECT COALESCE(SUM(value), 0) / (60 * 60 * 24)::float
       FROM metric_type
 INNER JOIN metric_instance USING (metric_type_id)
      WHERE name = 'total_wall_clock_time_in_seconds')::numeric, 2) AS total_wall_clock_time_in_days,
    round((SELECT COALESCE(SUM(value), 0) / (60 * 60 * 24)::float
       FROM metric_type
 INNER JOIN metric_instance USING (metric_type_id)
      WHERE name = 'max_cpu_usage')::numeric, 2) AS total_cpu_time_in_days,
    round((SELECT COALESCE(SUM(value), 0) * 10e-6
       FROM metric_type
 INNER JOIN metric_instance USING (metric_type_id)
      WHERE name = 'n_contigs_gt_0')::numeric, 2) AS n_millions_of_contigs_generated,
    round((SELECT COALESCE(SUM(value), 0) * 10e-9
       FROM metric_type
 INNER JOIN metric_instance USING (metric_type_id)
      WHERE name = 'total_length_gt_0')::numeric, 2) AS length_of_all_contigs_generated_in_gb;
