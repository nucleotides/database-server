INSERT INTO "file_instance" ("file_type_id","sha256","url")
VALUES ((SELECT id FROM file_type WHERE name = 'short_read_fastq'), '7673a', 's3://reads'),
       ((SELECT id FROM file_type WHERE name = 'short_read_fastq'), 'c1f0f', 's3://reads');
--;
INSERT INTO "input_data_file" ("input_data_file_set_id", "file_instance_id")
VALUES ((SELECT id FROM input_data_file_set WHERE name   = 'jgi_microbe_00001'),
        (SELECT id FROM file_instance       WHERE sha256 = '7673a')),
       ((SELECT id FROM input_data_file_set WHERE name   = 'jgi_microbe_00001'),
        (SELECT id FROM file_instance       WHERE sha256 = 'c1f0f'));
