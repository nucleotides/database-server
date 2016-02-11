INSERT INTO input_data_source (name, description, source_type_id)
VALUES ('kansas_farm_soil', 'desc', (SELECT id FROM source_type WHERE name = 'metagenome'));

WITH source_ AS (
	INSERT INTO input_data_source (name, description, source_type_id)
	VALUES ('ecoli_k12', 'desc', (SELECT id FROM source_type WHERE name = 'microbe'))
	RETURNING id
),
files_ AS (
	INSERT INTO file_instance (file_type_id, sha256, url)
	VALUES ((SELECT id FROM file_type WHERE name = 'reference_fasta'), 'd421a4', 's3://ref')
	RETURNING id
)
INSERT INTO input_data_source_reference_file (input_data_source_id, file_instance_id)
SELECT * FROM source_ CROSS JOIN files_;
