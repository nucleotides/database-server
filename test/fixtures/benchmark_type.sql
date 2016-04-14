INSERT INTO "benchmark_type" ("name", "description", "product_image_type_id", "evaluation_image_type_id")
       VALUES ('illumina_isolate_reference_assembly',
	       'Evaluate genome assemblers using reads and reference genome',
	       (SELECT id FROM image_type WHERE name = 'short_read_assembler'),
	       (SELECT id FROM image_type WHERE name = 'reference_assembly_evaluation'));
