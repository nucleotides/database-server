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
        FROM task_expanded_fields
  INNER JOIN events_prioritised_by_successful USING (task_id)
  INNER JOIN event_file_instance              USING (event_id)
       WHERE task_type = 'produce'
         AND complete = true
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
SELECT
external_id	     AS id,
benchmark_type.name  AS type,
task_id
FROM benchmark_instance
LEFT JOIN benchmark_type  USING (benchmark_type_id)
LEFT JOIN task            USING (benchmark_instance_id)
WHERE external_id = :id

-- name: completed-benchmark-metrics
-- Get all metrics for successfully completed benchmarks
WITH events_prioritised_by_successful AS (
	SELECT DISTINCT ON (task_id) *
	FROM event
	ORDER by task_id, success, created_at DESC
),
tasks_per_image_by_benchmark_type AS (
	SELECT DISTINCT
		benchmark_type.id            AS benchmark_type_id,
		COUNT(product_image_task_id) AS n_tasks
	FROM benchmark_type
	JOIN benchmark_instance ON benchmark_instance.benchmark_type_id = benchmark_type.id
	JOIN task ON task.benchmark_instance_id = benchmark_instance.id
	GROUP by benchmark_type.id, product_image_task_id
),
image_benchmarking_state AS (
	SELECT
		benchmark_type_id,
		product_image_task_id,
		COUNT(event.id)                  AS n_completed_tasks,
		COUNT(event.id) / n_tasks::float AS perc_completed_tasks,
		COUNT(event.id) = n_tasks        AS completed,
		NOT bool_and(event.success)      AS benchmarking_errors
	FROM benchmark_instance
	LEFT JOIN task ON task.benchmark_instance_id = benchmark_instance.id
	LEFT JOIN events_prioritised_by_successful AS event ON event.task_id = task.id
	LEFT JOIN tasks_per_image_by_benchmark_type AS task_per_image USING(benchmark_type_id)
	GROUP BY benchmark_type_id, n_tasks, product_image_task_id
	ORDER BY product_image_task_id, benchmark_type_id ASC
),
successful_benchmark_metrics AS (
	SELECT
		benchmark_instance.id AS benchmark_instance_id,
		metric_type.name,
		metric_instance.value
	FROM events_prioritised_by_successful AS event
	LEFT JOIN task ON task.id = event.task_id
	LEFT JOIN benchmark_instance  ON benchmark_instance.id = task.benchmark_instance_id
	LEFT JOIN metric_instance     ON metric_instance.event_id = event.id
	LEFT JOIN metric_type         ON metric_type.id = metric_instance.metric_type_id
	WHERE event.success = TRUE
)
SELECT
	benchmark_instance.external_id AS benchmark,
	image_type.name                AS image_type,
	image_instance.name            AS image_name,
	image_version.name             AS image_version,
	image_task.name                AS image_task,
	biological_source.name         AS source_name,
	source_type.name               AS source_type,
	input_data_file_set.name       AS source_data_set,
        file_instance.sha256           AS input_file_id,
	metric.name                    AS metric_name,
	metric.value                   AS metric_value
FROM image_benchmarking_state AS image
LEFT JOIN image_task                             ON image.product_image_task_id = image_task.id -- split out image expanded fields table here
LEFT JOIN image_version                          ON image_version.id = image_task.image_version_id
LEFT JOIN image_instance                         ON image_instance.id = image_version.image_instance_id
LEFT JOIN image_type                             ON image_type.id = image_instance.image_type_id -- end split out
LEFT JOIN benchmark_instance                     USING (product_image_task_id)
LEFT JOIN input_data_file                        ON benchmark_instance.input_data_file_id = input_data_file.id -- split input data files expanded fields table here
LEFT JOIN file_instance                          ON file_instance.id = input_data_file.file_instance_id
LEFT JOIN input_data_file_set                    ON input_data_file.input_data_file_set_id = input_data_file_set.id
LEFT JOIN biological_source                      ON input_data_file_set.biological_source_id = biological_source.id
LEFT JOIN source_type                            ON biological_source.source_type_id = source_type.id -- end split out
LEFT JOIN successful_benchmark_metrics AS metric ON metric.benchmark_instance_id = benchmark_instance.id
WHERE image.completed = true
AND image.benchmarking_errors = false
