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
--;;
INSERT INTO benchmark_event (benchmark_instance_id, benchmark_file, log_file, event_type, success)
VALUES ('2f221a18eb86380369570b2ed147d8b4', 's3://url', 's3://url', 'product', true);
--;;
INSERT INTO benchmark_event (benchmark_instance_id, benchmark_file, log_file, event_type, success)
VALUES ('2f221a18eb86380369570b2ed147d8b4', 's3://url', 's3://url', 'evaluation', true);
--;;
INSERT INTO metric_instance (metric_type_id, benchmark_event_id, value)
VALUES (1, 2, 20000), (2, 2, 10);
