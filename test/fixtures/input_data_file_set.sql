INSERT INTO input_data_file_set (
  name,
  description,
  platform_type_id,
  run_mode_type_id,
  protocol_type_id,
  material_type_id,
  extraction_method_type_id,
  biological_source_id
)
VALUES ('regular_fragment_1',
	'desc',
	(SELECT platform_type_id          FROM platform_type          WHERE name = 'miseq'),
	(SELECT run_mode_type_id          FROM run_mode_type 	      WHERE name = '2x150_300'),
	(SELECT protocol_type_id          FROM protocol_type          WHERE name = 'unamplified_regular_fragment'),
	(SELECT material_type_id          FROM material_type          WHERE name = 'dna'),
	(SELECT extraction_method_type_id FROM extraction_method_type WHERE name = 'cultured_colony_isolate'),
	(SELECT biological_source_id      FROM biological_source      WHERE name = 'amycolatopsis_sulphurea_dsm_46092')),

	('regular_fragment_1',
	'desc',
	(SELECT platform_type_id          FROM platform_type          WHERE name = 'miseq'),
	(SELECT run_mode_type_id          FROM run_mode_type 	      WHERE name = '2x150_300'),
	(SELECT protocol_type_id          FROM protocol_type          WHERE name = 'unamplified_regular_fragment'),
	(SELECT material_type_id          FROM material_type          WHERE name = 'dna'),
	(SELECT extraction_method_type_id FROM extraction_method_type WHERE name = 'cultured_colony_isolate'),
	(SELECT biological_source_id      FROM biological_source      WHERE name = 'saccharopolyspora_spinosa_dsm_44228'))
