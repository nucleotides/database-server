--;;
--;; Metadata Types
--;;
CREATE OR REPLACE FUNCTION rename_primary_key(table_name varchar(50))
  RETURNS VOID AS
$func$
BEGIN
EXECUTE format('
ALTER TABLE %1$s DROP CONSTRAINT %2$s cascade;
ALTER TABLE %1$s RENAME COLUMN id TO %3$s;
ALTER TABLE %1$s ADD PRIMARY KEY (%3$s);
', table_name, table_name || '_pkey', table_name || '_id');
END
$func$ LANGUAGE plpgsql;
--;;
CREATE OR REPLACE FUNCTION create_foreign_key(src varchar(50), dst varchar(50))
  RETURNS VOID AS
$func$
BEGIN
EXECUTE format('
ALTER TABLE %1$s
  ADD CONSTRAINT %4$s FOREIGN KEY (%2$s)
      REFERENCES %3$s (%2$s)
', src, dst || '_id', dst, src || '_to_' || dst || '_fkey');
END
$func$ LANGUAGE plpgsql;
--;;
DO $$
BEGIN
	PERFORM rename_primary_key('metric_type');
	PERFORM create_foreign_key('metric_instance', 'metric_type');

	PERFORM rename_primary_key('file_type');
	PERFORM create_foreign_key('file_instance', 'file_type');

	PERFORM rename_primary_key('image_type');
	PERFORM create_foreign_key('image_instance', 'image_type');
	ALTER TABLE benchmark_type
	  ADD CONSTRAINT benchmark_type_product_image_type_id_fkey FOREIGN KEY (product_image_type_id)
	      REFERENCES image_type (image_type_id);
	ALTER TABLE benchmark_type
	  ADD CONSTRAINT benchmark_type_evaluation_image_type_id_fkey FOREIGN KEY (evaluation_image_type_id)
	      REFERENCES image_type (image_type_id);
	ALTER TABLE benchmark_instance DROP COLUMN product_image_instance_id;

	PERFORM rename_primary_key('platform_type');
	PERFORM create_foreign_key('input_data_file_set', 'platform_type');

	PERFORM rename_primary_key('run_mode_type');
	PERFORM create_foreign_key('input_data_file_set', 'run_mode_type');

	PERFORM rename_primary_key('protocol_type');
	PERFORM create_foreign_key('input_data_file_set', 'protocol_type');

	PERFORM rename_primary_key('source_type');
	PERFORM create_foreign_key('biological_source', 'source_type');

	PERFORM rename_primary_key('extraction_method_type');
	PERFORM create_foreign_key('input_data_file_set', 'extraction_method_type');

	PERFORM rename_primary_key('material_type');
	PERFORM create_foreign_key('input_data_file_set', 'material_type');

	PERFORM rename_primary_key('file_instance');
	PERFORM create_foreign_key('biological_source_reference_file', 'file_instance');
	PERFORM create_foreign_key('input_data_file', 'file_instance');
	PERFORM create_foreign_key('event_file_instance', 'file_instance');

	PERFORM rename_primary_key('biological_source');
	PERFORM create_foreign_key('biological_source_reference_file', 'biological_source');
	PERFORM create_foreign_key('input_data_file_set', 'biological_source');

	PERFORM rename_primary_key('biological_source_reference_file');

	PERFORM rename_primary_key('input_data_file_set');
	PERFORM create_foreign_key('input_data_file', 'input_data_file_set');
	PERFORM create_foreign_key('benchmark_data', 'input_data_file_set');

	PERFORM rename_primary_key('input_data_file');
	PERFORM create_foreign_key('benchmark_instance', 'input_data_file');

	PERFORM rename_primary_key('image_instance');
	PERFORM create_foreign_key('image_version', 'image_instance');
	ALTER TABLE benchmark_instance DROP COLUMN product_image_version_id;

	PERFORM rename_primary_key('image_version');
	PERFORM create_foreign_key('image_task', 'image_version');

	PERFORM rename_primary_key('image_task');
	PERFORM create_foreign_key('task', 'image_task');
	ALTER TABLE benchmark_instance
	  ADD CONSTRAINT benchmark_instance_product_image_task_id_fkey FOREIGN KEY (product_image_task_id)
	      REFERENCES image_task (image_task_id);

	PERFORM rename_primary_key('benchmark_type');
	PERFORM create_foreign_key('benchmark_data', 'benchmark_type');
	PERFORM create_foreign_key('benchmark_instance', 'benchmark_type');

	PERFORM rename_primary_key('benchmark_data');

	PERFORM rename_primary_key('benchmark_instance');
	PERFORM create_foreign_key('task', 'benchmark_instance');

	PERFORM rename_primary_key('task');
	PERFORM create_foreign_key('event', 'task');

	PERFORM rename_primary_key('event');
	PERFORM create_foreign_key('event_file_instance', 'event');
	PERFORM create_foreign_key('metric_instance', 'event');

	PERFORM rename_primary_key('event_file_instance');

	PERFORM rename_primary_key('metric_instance');
END$$;
--;;
--;; Updated functions for populating benchmark_instance and task
--;;
CREATE OR REPLACE FUNCTION populate_benchmark_instance () RETURNS void AS $$
BEGIN
INSERT INTO benchmark_instance(
	benchmark_type_id,
	input_data_file_id,
	product_image_task_id,
	file_instance_id)
SELECT
benchmark_type_id,
input_data_file_id,
image_task_id,
file_instance_id
FROM benchmark_type
LEFT JOIN benchmark_data      USING (benchmark_type_id)
LEFT JOIN input_data_file_set USING (input_data_file_set_id)
LEFT JOIN input_data_file     USING (input_data_file_set_id)
LEFT JOIN file_instance       USING (file_instance_id)
LEFT JOIN image_type          ON image_type.image_type_id = benchmark_type.product_image_type_id
INNER JOIN image_instance     USING (image_type_id)
LEFT JOIN image_version       USING (image_instance_id)
LEFT JOIN image_task          USING (image_version_id)
ORDER BY benchmark_type_id,
	 input_data_file_id,
	 image_task_id ASC
ON CONFLICT DO NOTHING;
END; $$
LANGUAGE PLPGSQL;
--;;
CREATE OR REPLACE FUNCTION populate_task () RETURNS void AS $$
BEGIN
INSERT INTO task (benchmark_instance_id, image_task_id, task_type)
	SELECT
	benchmark_instance_id,
	image_task_id,
	'evaluate'::task_type   AS task_type
	FROM benchmark_instance
	LEFT JOIN benchmark_type      USING (benchmark_type_id)
	LEFT JOIN image_instance      ON image_instance.image_type_id = benchmark_type.evaluation_image_type_id
	LEFT JOIN image_version       USING (image_instance_id)
	LEFT JOIN image_task          USING (image_version_id)
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
CREATE OR REPLACE FUNCTION create_file_instance(digest TEXT, file_name TEXT, file_url TEXT)
RETURNS integer AS $$
  INSERT INTO file_instance (file_type_id, sha256, url)
  SELECT (SELECT file_type_id FROM file_type WHERE name = $2 LIMIT 1), $1, $3
  ON CONFLICT DO NOTHING;
  SELECT file_instance_id FROM file_instance WHERE sha256 = $1
$$ LANGUAGE SQL;
