INSERT INTO "benchmark_type" ("name","description","product_image_type_id","evaluation_image_type_id")
VALUES
	('illumina_isolate_reference_assembly',
	'desc',
	(SELECT id FROM image_type WHERE name = 'short_read_assembler'),
	(SELECT id FROM image_type WHERE name = 'reference_assembly_evaluation')),
	('short_read_preprocessing_reference_evaluation',
	'desc',
	(SELECT id FROM image_type WHERE name = 'short_read_preprocessor'),
	(SELECT id FROM image_type WHERE name = 'short_read_preprocessing_reference_evaluation'));
--;;
INSERT INTO "benchmark_data" ("benchmark_type_id", "input_data_file_set_id")
VALUES
	((SELECT id FROM benchmark_type      WHERE name = 'illumina_isolate_reference_assembly'),
	 (SELECT id FROM input_data_file_set WHERE name = 'jgi_isolate_microbe_2x150_1')),
	((SELECT id FROM benchmark_type      WHERE name = 'short_read_preprocessing_reference_evaluation'),
	 (SELECT id FROM input_data_file_set WHERE name = 'jgi_isolate_microbe_2x150_1'));
