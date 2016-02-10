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
  WHERE benchmark_instance.id = :id::int
),
reference_files AS (
  SELECT
  input_data_source_reference_file.file_instance_id AS file_instance_id
  FROM _benchmark
  LEFT JOIN input_data_file                  ON input_data_file.id = _benchmark.input_data_file_id
  LEFT JOIN input_data_file_set              ON input_data_file_set.id = input_data_file.input_data_file_set_id
  LEFT JOIN input_data_source_reference_file ON input_data_source_reference_file.input_data_source_id = input_data_file_set.input_data_source_id
),
produce_files AS (
  SELECT
  event_file_instance.file_instance_id AS file_instance_id
  FROM _benchmark
  LEFT JOIN task                 ON task.benchmark_instance_id = _benchmark.id
  LEFT JOIN event                ON event.task_id = task.id
  LEFT JOIN event_file_instance  ON event_file_instance.event_id = event.id
  WHERE task.task_type = 'produce'
  AND event.success = true
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
WHERE file_type.name != 'log'


-- name: benchmark-by-id
-- Get a benchmark entry by ID
SELECT
GREATEST(
	benchmark_instance.created_at,
	image_instance.created_at,
	image_instance_task.created_at)	AS created_at,
benchmark_instance.external_id		AS id,
image_instance_task.task		AS image_task,
image_instance.name			AS image_name,
image_instance.sha256			AS image_sha256,
image_type.name				AS image_type,
benchmark_type.name
FROM benchmark_instance
LEFT JOIN image_instance_task	ON image_instance_task.id = benchmark_instance.product_image_instance_task_id
LEFT JOIN image_instance	ON image_instance.id      = image_instance_task.image_instance_id
LEFT JOIN image_type            ON image_type.id          = image_instance.image_type_id
LEFT JOIN benchmark_type	ON benchmark_type.id      = benchmark_instance.benchmark_type_id
WHERE external_id = :id
LIMIT 1


-- name: benchmark-event-files
-- Get all event files associated with a benchmark
SELECT
task.id,
task.task_type,
image_instance_task.task	AS image_task,
image_instance.name		AS image_name,
image_instance.sha256		AS image_sha256,
image_type.name			AS image_type,
event.id			AS event_id,
event.created_at		AS event_created_at,
event.success			AS event_success,
file_type.name			AS file_type,
file_instance.sha256,
file_instance.url
FROM benchmark_instance
LEFT JOIN task			ON task.benchmark_instance_id	= benchmark_instance.id
LEFT JOIN image_instance_task	ON image_instance_task.id	= task.image_instance_task_id
LEFT JOIN image_instance	ON image_instance.id		= image_instance_task.image_instance_id
LEFT JOIN image_type            ON image_type.id		= image_instance.image_type_id
LEFT JOIN event			ON event.task_id		= task.id
LEFT JOIN event_file_instance	ON event_file_instance.event_id	= event.id
LEFT JOIN file_instance		ON file_instance.id		= event_file_instance.file_instance_id
LEFT JOIN file_type		ON file_type.id			= file_instance.file_type_id
WHERE external_id = :id


-- name: benchmark-metrics-by-id
-- Get metrics for a benchmark entry by ID
SELECT DISTINCT ON (metric_type.id)
metric_type.name,
metric_instance.value
FROM benchmark_instance
LEFT JOIN task			ON task.benchmark_instance_id = benchmark_instance.id
LEFT JOIN event			ON event.task_id = task.id
RIGHT JOIN metric_instance	ON metric_instance.event_id = event.id
LEFT JOIN metric_type		ON metric_type.id = metric_instance.metric_type_id
WHERE benchmark_instance.external_id = :id
AND event.success = TRUE
