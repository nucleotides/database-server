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
WITH _benchmark AS (
  SELECT *
  FROM benchmark_instance
  WHERE benchmark_instance_id = :id::int
),
_first_successful_produce_event AS (
  SELECT event.*
  FROM _benchmark
  LEFT JOIN task  USING (benchmark_instance_id)
  LEFT JOIN event USING (task_id)
  WHERE task_type = 'produce'
  AND event.success = true
  LIMIT 1
),
reference_files AS (
  SELECT
  biological_source_reference_file.file_instance_id
  FROM _benchmark
  LEFT JOIN input_data_file                  USING (input_data_file_id)
  LEFT JOIN input_data_file_set              USING (input_data_file_set_id)
  LEFT JOIN biological_source_reference_file USING (biological_source_id)
),
produce_files AS (
  SELECT
  file_instance_id
  FROM _first_successful_produce_event
  LEFT JOIN event_file_instance USING (event_id)
)
SELECT
sha256,
url,
file_type.name AS type
FROM (
  SELECT * FROM reference_files
  UNION ALL
  SELECT * FROM produce_files
) AS files
LEFT JOIN file_instance USING (file_instance_id)
LEFT JOIN file_type     USING (file_type_id)
WHERE file_type.name NOT IN ('container_log', 'container_runtime_metrics')


-- name: benchmark-by-id
-- Get a benchmark entry by ID
SELECT
external_id	     AS id,
benchmark_type.name  AS type,
task_id
FROM benchmark_instance
LEFT JOIN benchmark_type  USING (benchmark_type_id)
LEFT JOIN task            USING (benchmark_instance_id)
WHERE external_id = :id
