INSERT INTO "file_instance"("file_type_id", "sha256", "url")
VALUES ((SELECT id FROM file_type WHERE name = 'reference_fasta'), 'd421a4', 's3://ref');
--;;
INSERT INTO "biological_source_reference_file" ("biological_source_id", "file_instance_id")
VALUES (1, (SELECT id FROM file_instance WHERE sha256 = 'd421a4'))
