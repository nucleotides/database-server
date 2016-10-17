INSERT INTO "image_instance" ("image_type_id","name")
VALUES
	((SELECT image_type_id FROM image_type WHERE name = 'short_read_assembler')         , 'bioboxes/velvet'),
	((SELECT image_type_id FROM image_type WHERE name = 'short_read_assembler')         , 'bioboxes/ray'   ),
	((SELECT image_type_id FROM image_type WHERE name = 'reference_assembly_evaluation'), 'bioboxes/quast' );


INSERT INTO "image_version" ("image_instance_id", "sha256", "name")
VALUES
	((SELECT image_instance_id FROM image_instance WHERE name = 'bioboxes/velvet'), 'digest_1', 'ver_1'),
	((SELECT image_instance_id FROM image_instance WHERE name = 'bioboxes/ray'   ), 'digest_2', 'ver_2'),
	((SELECT image_instance_id FROM image_instance WHERE name = 'bioboxes/quast' ), 'digest_3', 'ver_3');

INSERT INTO "image_task" ("image_version_id", "name")
VALUES
	((SELECT image_version_id FROM image_version WHERE sha256 = 'digest_1') , 'default'),
	((SELECT image_version_id FROM image_version WHERE sha256 = 'digest_1') , 'careful'),
	((SELECT image_version_id FROM image_version WHERE sha256 = 'digest_2') , 'default'),
	((SELECT image_version_id FROM image_version WHERE sha256 = 'digest_3') , 'default');
