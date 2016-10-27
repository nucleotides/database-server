SELECT create_file_instance('d421a4', 'reference_fasta', 's3://ref');
--;;
INSERT INTO "biological_source_reference_file" ("biological_source_id", "file_instance_id")
VALUES (1, (SELECT file_instance_id FROM file_instance WHERE sha256 = 'd421a4'))
