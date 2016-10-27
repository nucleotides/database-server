-- name: benchmark-produce-files-by-id
-- Get all input produce files by benchmark-instance-id
SELECT
sha256,
url,
file_type AS type
FROM benchmark_instance
LEFT JOIN input_data_file_expanded_fields USING (input_data_file_id)
WHERE benchmark_instance_id = :id::int


-- name: benchmark-evaluate-files-by-id
-- Get all input produce files by benchmark-instance-id
WITH reference_files AS (
      SELECT biological_source_reference_file.file_instance_id,
             benchmark_instance_id
        FROM benchmark_instance
  INNER JOIN input_data_file                  USING (input_data_file_id)
  INNER JOIN input_data_file_set              USING (input_data_file_set_id)
  INNER JOIN biological_source_reference_file USING (biological_source_id)
),
produce_files AS (
      SELECT file_instance_id,
             benchmark_instance_id
        FROM task_expanded_fields AS task
  INNER JOIN events_prioritised_by_successful USING (task_id)
  INNER JOIN event_file_instance              USING (event_id)
       WHERE task_type = 'produce'
         AND task.complete  = true
         AND task.success   = true
)
    SELECT sha256,
           url,
           file_type.name AS type
      FROM (SELECT * FROM reference_files
            UNION ALL
            SELECT * FROM produce_files) AS files
INNER JOIN file_instance USING (file_instance_id)
INNER JOIN file_type     USING (file_type_id)
     WHERE file_type.name NOT IN ('container_log', 'container_runtime_metrics')
       AND benchmark_instance_id = :id::int


-- name: benchmark-by-id
-- Get a benchmark entry by ID
WITH benchmark AS (
  SELECT *
    FROM task_expanded_fields
   WHERE external_id = :id
),
status AS (
  SELECT benchmark_instance_id,
         (produce_task.complete AND NOT produce_task.success)
      OR bool_and(benchmark.complete) AS complete,
         bool_and(benchmark.success)  AS success
    FROM benchmark
    JOIN (SELECT *
            FROM benchmark
           WHERE task_type = 'produce'
           LIMIT 1) AS produce_task USING (benchmark_instance_id)
GROUP BY benchmark_instance_id, produce_task.complete, produce_task.success
)
SELECT external_id         AS id,
       benchmark_type_name AS type,
       task_id,
       status.complete,
       status.success
  FROM benchmark
  JOIN status USING (benchmark_instance_id)
