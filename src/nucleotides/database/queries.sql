-- name: save-biological-source<!
-- Creates a new input data source entry
INSERT INTO biological_source (name, description, source_type_id)
VALUES (:name, :desc, (SELECT source_type_id FROM source_type WHERE name = :source_type))
ON CONFLICT DO NOTHING

-- name: save-biological-source-file<!
-- Creates link between biological_source and reference file_instance
WITH _file AS (
  SELECT create_file_instance(:sha256, :file_type, :url) AS file_instance_id
),
_biological_source AS (
  SELECT * FROM biological_source WHERE name = :source_name
)
INSERT INTO biological_source_reference_file (biological_source_id, file_instance_id)
VALUES ((SELECT biological_source_id FROM _biological_source), (SELECT file_instance_id FROM _file))
ON CONFLICT DO NOTHING

-- name: save-input-data-file-set<!
-- Creates a new input_data_file_set entry
INSERT INTO input_data_file_set (
  name,
  description,
  platform_type_id,
  protocol_type_id,
  run_mode_type_id,
  material_type_id,
  extraction_method_type_id,
  biological_source_id)
 VALUES (
  :name,
  :desc,
  (SELECT platform_type_id          FROM platform_type WHERE name = :platform_type),
  (SELECT protocol_type_id          FROM protocol_type WHERE name = :protocol_type),
  (SELECT run_mode_type_id          FROM run_mode_type WHERE name = :run_mode_type),
  (SELECT material_type_id          FROM material_type WHERE name = :material_type),
  (SELECT extraction_method_type_id FROM extraction_method_type WHERE name = :extraction_method_type),
  (SELECT biological_source_id      FROM biological_source WHERE name = :source_name))
ON CONFLICT DO NOTHING

-- name: save-input-data-file<!
-- Creates link between 'input_data_file_set' and 'file_instance'
WITH _file AS (
  SELECT create_file_instance(:sha256, :file_type, :url) AS file_instance_id
),
_input_data_file_set AS (
  SELECT *
  FROM input_data_file_set
  WHERE name                 = :file_set_name
    AND biological_source_id = (SELECT biological_source_id
				FROM biological_source
				WHERE name = :source_name)
)
INSERT INTO input_data_file (input_data_file_set_id, file_instance_id)
VALUES ((SELECT input_data_file_set_id FROM _input_data_file_set), (SELECT file_instance_id FROM _file))
ON CONFLICT DO NOTHING

-- name: save-image-instance<!
-- Creates a new Docker image instance entry
INSERT INTO image_instance (name, image_type_id)
VALUES (:image_name, (SELECT image_type_id FROM image_type WHERE name = :image_type))
ON CONFLICT DO NOTHING

-- name: save-image-version<!
-- Creates a new Docker version entry
INSERT INTO image_version (sha256, name, image_instance_id)
VALUES (:sha256, :version_name, (SELECT image_instance_id FROM image_instance WHERE name = :image_name))
ON CONFLICT DO NOTHING

-- name: save-image-task<!
-- Creates a new Docker task entry
INSERT INTO image_task (name, image_version_id)
VALUES (:task, (SELECT image_version_id FROM image_version WHERE sha256 = :sha256))
ON CONFLICT DO NOTHING

-- name: save-benchmark-type<!
-- Creates a new benchmark type entry
INSERT INTO benchmark_type (name, description, product_image_type_id, evaluation_image_type_id)
VALUES (:name,
        :desc,
	(SELECT image_type_id FROM image_type WHERE name = :product_image_type),
	(SELECT image_type_id FROM image_type WHERE name = :evaluation_image_type))
ON CONFLICT DO NOTHING

-- name: save-benchmark-data<!
-- Creates a new benchmark type entry
WITH _input_data_file_set AS (
  SELECT input_data_file_set_id
  FROM input_data_file_set
  WHERE name                 = :file_set_name
    AND biological_source_id = (SELECT biological_source_id
				FROM biological_source
				WHERE name = :source_name)
),
_benchmark AS (
  SELECT benchmark_type_id
  FROM benchmark_type
  WHERE name = :benchmark_name
)
INSERT INTO benchmark_data (input_data_file_set_id, benchmark_type_id)
VALUES ((SELECT input_data_file_set_id FROM _input_data_file_set), (SELECT benchmark_type_id FROM _benchmark))
ON CONFLICT DO NOTHING

-- name: populate-instance-and-task!
-- Populates benchmark instance table with combinations of data record and image task
DO $$
BEGIN
PERFORM populate_benchmark_instance();
PERFORM populate_task();
END$$
