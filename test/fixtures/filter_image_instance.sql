INSERT INTO "image_instance" ("image_type_id","name","sha256")
VALUES
	((SELECT image_type_id FROM image_type WHERE name = 'short_read_preprocessor')                       , 'bioboxes/my-filterer'       , 'digest_3'),
	((SELECT image_type_id FROM image_type WHERE name = 'short_read_preprocessing_reference_evaluation') , 'bioboxes/velvet-then-quast' , 'digest_4');

INSERT INTO "image_instance_task" ("image_instance_id","task")
VALUES
	((SELECT image_instance_id FROM image_instance WHERE name = 'bioboxes/my-filterer')       , 'default'),
	((SELECT image_instance_id FROM image_instance WHERE name = 'bioboxes/velvet-then-quast') , 'default');
