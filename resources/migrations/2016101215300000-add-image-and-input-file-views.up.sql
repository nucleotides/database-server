--;;
--;; Input data file fully denormalised
--;;
CREATE MATERIALIZED VIEW input_data_file_expanded_fields AS
SELECT
file_instance_id,
file_type_id,
input_data_file_set_id,
input_data_file_id,
biological_source_id,
platform_type_id,
protocol_type_id,
material_type_id,
extraction_method_type_id,
run_mode_type_id,
file_instance.created_at       AS file_instance_created_at,
input_data_file_set.created_at AS input_file_set_created_at,
input_data_file.created_at     AS input_file_created_at,
file_type.name                 AS file_type,
platform_type.name             AS platform,
protocol_type.name             AS protocol,
material_type.name             AS material,
extraction_method_type.name    AS extraction_method,
run_mode_type.name             AS run_mode,
source_type.name               AS biological_source_type,
biological_source.name         AS biological_source_name,
input_data_file_set.name       AS input_file_set_name,
input_data_file_set.active     AS input_file_set_active,
input_data_file.active         AS input_file_active,
biological_source.active       AS biological_source_active,
sha256,
url
FROM input_data_file
INNER JOIN file_instance          USING (file_instance_id)
INNER JOIN input_data_file_set    USING (input_data_file_set_id)
INNER JOIN biological_source      USING (biological_source_id)
INNER JOIN source_type            USING (source_type_id)
INNER JOIN file_type              USING (file_type_id)
INNER JOIN platform_type          USING (platform_type_id)
INNER JOIN protocol_type          USING (protocol_type_id)
INNER JOIN material_type          USING (material_type_id)
INNER JOIN extraction_method_type USING (extraction_method_type_id)
INNER JOIN run_mode_type          USING (run_mode_type_id);
--;;
CREATE INDEX ON input_data_file_expanded_fields (file_instance_id);
--;;
CREATE INDEX ON input_data_file_expanded_fields (file_type_id);
--;;
CREATE INDEX ON input_data_file_expanded_fields (input_data_file_set_id);
--;;
CREATE INDEX ON input_data_file_expanded_fields (input_data_file_id);
--;;
CREATE INDEX ON input_data_file_expanded_fields (biological_source_id);
--;;
CREATE INDEX ON input_data_file_expanded_fields (platform_type_id);
--;;
CREATE INDEX ON input_data_file_expanded_fields (protocol_type_id);
--;;
CREATE INDEX ON input_data_file_expanded_fields (material_type_id);
--;;
CREATE INDEX ON input_data_file_expanded_fields (extraction_method_type_id);
--;;
CREATE INDEX ON input_data_file_expanded_fields (run_mode_type_id);


--;;
--;; Materialised view of denormalised image data
--;;
CREATE MATERIALIZED VIEW image_expanded_fields AS
SELECT
image_type_id,
image_instance_id,
image_version_id,
image_task_id,
image_type.created_at     AS image_type_created_at,
image_instance.created_at AS image_instance_created_at,
image_version.created_at  AS image_version_created_at,
image_task.created_at     AS image_task_created_at,
image_type.name           AS image_type_name,
image_instance.name       AS image_instance_name,
image_version.name        AS image_version_name,
image_version.sha256      AS image_version_sha256,
image_task.name           AS image_task_name
FROM image_type
INNER JOIN image_instance USING (image_type_id)
INNER JOIN image_version  USING (image_instance_id)
INNER JOIN image_task     USING (image_version_id);
--;;
CREATE INDEX ON image_expanded_fields (image_type_id);
--;;
CREATE INDEX ON image_expanded_fields (image_instance_id);
--;;
CREATE INDEX ON image_expanded_fields (image_version_id);
--;;
CREATE INDEX ON image_expanded_fields (image_task_id);
--;;
--;; Combination of image fields are unique
CREATE UNIQUE INDEX ON image_expanded_fields (image_type_id, image_instance_id, image_version_id, image_task_id);


--;;
--;; View of numbers of tasks per benchmark type
--;;
CREATE MATERIALIZED VIEW tasks_per_image_by_benchmark_type AS
SELECT DISTINCT benchmark_type_id,
		COUNT(product_image_task_id) AS n_tasks
	   FROM benchmark_type
	   JOIN benchmark_instance USING (benchmark_type_id)
	   JOIN task               USING (benchmark_instance_id)
       GROUP BY benchmark_type_id, product_image_task_id;
--;;
CREATE UNIQUE INDEX ON tasks_per_image_by_benchmark_type (benchmark_type_id);


--;;
--;; Updated function for populating benchmark_instances using
--;; the new materialised views for data and images
--;;
CREATE OR REPLACE FUNCTION populate_benchmark_instance () RETURNS void AS $$
BEGIN
INSERT INTO benchmark_instance(
	benchmark_type_id,
	product_image_task_id,
	input_data_file_id,
	file_instance_id)
SELECT
benchmark_type_id,
image_task_id,
input_data_file_id,
file_instance_id
FROM benchmark_type
INNER JOIN benchmark_data                            USING (benchmark_type_id)
INNER JOIN image_expanded_fields           AS images ON images.image_type_id = benchmark_type.product_image_type_id
INNER JOIN input_data_file_expanded_fields AS inputs USING (input_data_file_set_id)
ORDER BY benchmark_type_id, input_data_file_id, image_instance_id, image_task_id ASC
ON CONFLICT DO NOTHING;
END; $$
LANGUAGE PLPGSQL;


--;;
--;; Updated function for populating tasks using
--;; the new materialised views for data and images
--;;
CREATE OR REPLACE FUNCTION populate_task () RETURNS void AS $$
BEGIN
INSERT INTO task (benchmark_instance_id, image_task_id, task_type)
	SELECT
	benchmark_instance_id,
	images.image_task_id,
	'evaluate'::task_type AS task_type
	FROM benchmark_instance
	INNER JOIN benchmark_type                  USING (benchmark_type_id)
	INNER JOIN image_expanded_fields AS images ON images.image_type_id = benchmark_type.evaluation_image_type_id
UNION
	SELECT
	benchmark_instance_id,
	benchmark_instance.product_image_task_id AS image_task_id,
	'produce'::task_type                     AS task_type
	FROM benchmark_instance
EXCEPT
	SELECT
	benchmark_instance_id,
	image_task_id,
	task_type
	FROM task
ORDER BY benchmark_instance_id, image_task_id, task_type ASC;
END; $$
LANGUAGE PLPGSQL;


--;;
--;; Single events per task prioritised by the successful over the failed and
--;; oldest first
--;;
CREATE VIEW events_prioritised_by_successful AS
SELECT DISTINCT ON (task_id) *
FROM event
ORDER by task_id, success DESC, created_at ASC;


--;;
--;; Simplify task view table using new materialsed views
--;;
DROP VIEW task_expanded_fields;
--;;
CREATE OR REPLACE VIEW task_expanded_fields AS
SELECT
task_id,
benchmark_instance_id,
benchmark_instance.external_id,
benchmark_type.name              AS benchmark_type_name,
task_type,
image_instance_name              AS image_name,
image_version_name               AS image_version,
image_version_sha256             AS image_sha256,
image_task_name                  AS image_task,
image_type_name                  AS image_type,
events.event_id IS NOT NULL      AS complete,
COALESCE (events.success, FALSE) AS success
FROM task
LEFT JOIN image_expanded_fields            AS images USING (image_task_id)
LEFT JOIN benchmark_instance                         USING (benchmark_instance_id)
LEFT JOIN benchmark_type                             USING (benchmark_type_id)
LEFT JOIN events_prioritised_by_successful AS events USING (task_id);


--;;
--;; View for linking biological_source and input_data_set_names
--;; Cannot be materialised view as used during migration
--;;
CREATE VIEW biological_source_input_data_file_set AS
SELECT
input_data_file_set_id,
biological_source_id,
input_data_file_set.name AS input_data_file_set_name,
biological_source.name   AS biological_source_name
FROM input_data_file_set
INNER JOIN biological_source USING (biological_source_id);


--;;
--;; Create identifiable name for each benchmark instance
--;;
CREATE VIEW benchmark_instance_name AS
SELECT
benchmark_instance_id,
benchmark_type.name
  || ' '
  || image_instance_name
  || '/'
  || image_version_name
  || '/'
  || image_task_name
  || ' '
  || biological_source_name
  || '/'
  || input_file_set_name
  || '/'
  || sha256 AS name
FROM benchmark_instance
INNER JOIN benchmark_type                            USING (benchmark_type_id)
INNER JOIN image_expanded_fields           AS images ON images.image_task_id = benchmark_instance.product_image_task_id
INNER JOIN input_data_file_expanded_fields AS inputs USING (file_instance_id);



--;;
--;; View of the state of each image task by benchmark
--;;
CREATE VIEW image_task_benchmarking_state AS
     SELECT benchmark_type_id,
            product_image_task_id,
            n_tasks                                              AS task_total,
            COUNT(event_id)                                      AS task_completed,
            n_tasks - COUNT(event_id)                            AS task_outstanding,
            COUNT(event_id) / n_tasks::float                     AS task_proportion_completed,
            COUNT(event_id) filter (where event.success = false) AS task_errorful,
            COUNT(event_id) filter (where event.success = true)  AS task_successful,
            COUNT(event_id) = n_tasks                            AS benchmark_finished,
            COALESCE(bool_and(event.success), FALSE)             AS benchmark_successful,
            COUNT(event_id) || ' / ' || n_tasks                  AS benchmark_status
       FROM benchmark_instance
 INNER JOIN task                                                USING (benchmark_instance_id)
  LEFT JOIN events_prioritised_by_successful  AS event          USING (task_id)
 INNER JOIN tasks_per_image_by_benchmark_type AS task_per_image USING (benchmark_type_id)
   GROUP BY benchmark_type_id, n_tasks, product_image_task_id
   ORDER BY product_image_task_id, benchmark_type_id ASC;

--;;
--;; All metrics for completed benchmarks
--;;
CREATE VIEW completed_benchmark_metrics AS
     SELECT external_id                        AS benchmark_id,
            benchmark_instance_name.name       AS benchmark_name,
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
       FROM image_task_benchmarking_state   AS state
 INNER JOIN image_expanded_fields           AS image       ON state.product_image_task_id = image.image_task_id
 INNER JOIN benchmark_instance                             USING (product_image_task_id)
 INNER JOIN benchmark_type                                 ON benchmark_type.benchmark_type_id = benchmark_instance.benchmark_type_id
 INNER JOIN benchmark_instance_name                        USING (benchmark_instance_id)
 INNER JOIN input_data_file_expanded_fields AS input_file  USING (input_data_file_id)
 INNER JOIN task                                           USING (benchmark_instance_id)
 INNER JOIN events_prioritised_by_successful               USING (task_id)
 INNER JOIN metric_instance                                USING (event_id)
 INNER JOIN metric_type                                    USING (metric_type_id)
      WHERE state.benchmark_finished   = true
        AND state.benchmark_successful = true;



--;;
--;; Function rebuild all benchmark instances and tasks
--;;
CREATE OR REPLACE FUNCTION rebuild_benchmarks () RETURNS void AS $$
BEGIN
REFRESH MATERIALIZED VIEW input_data_file_expanded_fields;
REFRESH MATERIALIZED VIEW image_expanded_fields;
PERFORM populate_benchmark_instance();
PERFORM populate_task();
REFRESH MATERIALIZED VIEW tasks_per_image_by_benchmark_type;

REINDEX TABLE benchmark_instance;
REINDEX TABLE task;
REINDEX TABLE tasks_per_image_by_benchmark_type;
END; $$
LANGUAGE PLPGSQL;
