INSERT INTO metric_type (name, description)
VALUES ('ng50', 'An assembly metric'), ('lg50', 'Another assembly metric');
--;;
INSERT INTO image_type (name, description)
VALUES ('short_read_assembler', 'none');
--;;
INSERT INTO image_task (image_type_id, name, task, sha256, active)
VALUES (1, 'image', 'default', '123456', true);
--;;
INSERT INTO data_type (name,   library, type, description)
VALUES ('data', '2x150', 'isolate_genome', 'some_data');
--;;
INSERT INTO data_instance (data_type_id, entry_id, replicate,
	reads, input_url, reference_url, input_md5, reference_md5)
VALUES (1, 1, 1, 200000, 's3://url', 's3://url', '123456', '123456');
--;;
INSERT INTO benchmark_type (data_type_id, image_type_id, name)
VALUES (1, 1, 'short_read_assembly');
--;;
REFRESH MATERIALIZED VIEW benchmark_instance;
--;;
REINDEX TABLE benchmark_instance;
