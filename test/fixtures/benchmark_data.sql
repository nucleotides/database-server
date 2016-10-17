INSERT INTO "benchmark_data" ("benchmark_type_id", "input_data_file_set_id")
VALUES
	((SELECT benchmark_type_id      FROM benchmark_type      WHERE name = 'illumina_isolate_reference_assembly'),
	 (SELECT input_data_file_set_id FROM input_data_file_set WHERE name = 'regular_fragment_1'
					     AND   biological_source_id = (SELECT biological_source_id FROM biological_source LIMIT 1)));
