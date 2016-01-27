INSERT INTO input_data_source (name, description, source_type_id)
VALUES
	('ecoli_k12', 'desc', (SELECT id FROM source_type WHERE name = 'microbe')),
	('kansas_farm_soil', 'desc', (SELECT id FROM source_type WHERE name = 'metagenome'))
