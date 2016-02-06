INSERT INTO "image_instance" ("image_type_id","name","sha256")
VALUES
	((SELECT id FROM image_type WHERE name = 'short_read_assembler')         , 'bioboxes/velvet', 'digest_1'),
	((SELECT id FROM image_type WHERE name = 'short_read_assembler')         , 'bioboxes/ray'   , 'digest_2'),
	((SELECT id FROM image_type WHERE name = 'reference_assembly_evaluation'), 'bioboxes/quast' , 'digest_4');

INSERT INTO "image_instance_task" ("image_instance_id","task")
VALUES
	((SELECT id FROM image_instance WHERE name = 'bioboxes/velvet') , 'default'),
	((SELECT id FROM image_instance WHERE name = 'bioboxes/velvet') , 'careful'),
	((SELECT id FROM image_instance WHERE name = 'bioboxes/ray')    , 'default'),
	((SELECT id FROM image_instance WHERE name = 'bioboxes/quast')  , 'default');
