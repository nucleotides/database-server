-- name: benchmark-produce-files-by-id
-- Get all input produce files by benchmark-instance-id
SELECT
file_instance.sha256,
file_instance.url,
file_type.name AS type
FROM benchmark_instance
LEFT JOIN input_data_file ON input_data_file.id = benchmark_instance.input_data_file_id
LEFT JOIN file_instance   ON file_instance.id = input_data_file.file_instance_id
LEFT JOIN file_type       ON file_type.id = file_instance.file_type_id
WHERE benchmark_instance.id = :id::int


-- name: benchmark-evaluate-files-by-id
-- Get all input produce files by benchmark-instance-id
WITH _benchmark AS (
  SELECT *
  FROM benchmark_instance
  WHERE benchmark_instance.id = 1
),
_first_successful_produce_event AS (
  SELECT event.*
  FROM _benchmark
  LEFT JOIN task  ON task.benchmark_instance_id = _benchmark.id
  LEFT JOIN event ON event.task_id = task.id
  WHERE task.task_type = 'produce'
  AND event.success = true
  LIMIT 1
),
reference_files AS (
  SELECT
  biological_source_reference_file.file_instance_id AS file_instance_id
  FROM _benchmark
  LEFT JOIN input_data_file                  ON input_data_file.id = _benchmark.input_data_file_id
  LEFT JOIN input_data_file_set              ON input_data_file_set.id = input_data_file.input_data_file_set_id
  LEFT JOIN biological_source_reference_file ON biological_source_reference_file.biological_source_id = input_data_file_set.biological_source_id
),
produce_files AS (
  SELECT
  event_file_instance.file_instance_id AS file_instance_id
  FROM _first_successful_produce_event
  LEFT JOIN event_file_instance  ON event_file_instance.event_id = _first_successful_produce_event.id
),
_files AS (
  SELECT * FROM reference_files
  UNION ALL
  SELECT * FROM produce_files
)
SELECT
file_instance.sha256,
file_instance.url,
file_type.name AS type
FROM _files
LEFT JOIN file_instance ON file_instance.id = _files.file_instance_id
LEFT JOIN file_type     ON file_type.id = file_instance.file_type_id
WHERE file_type.name NOT IN ('container_log', 'container_runtime_metrics')


-- name: benchmark-by-id
-- Get a benchmark entry by ID
SELECT
benchmark_instance.external_id	AS id,
benchmark_type.name		AS type,
task.id				AS task_id
FROM benchmark_instance
LEFT JOIN benchmark_type	ON benchmark_type.id = benchmark_instance.benchmark_type_id
LEFT JOIN task			ON task.benchmark_instance_id = benchmark_instance.id
WHERE external_id = :id
