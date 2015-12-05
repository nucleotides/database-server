WITH product_image_type_ AS (
	INSERT INTO image_type (name, description)
	VALUES ('short_read_assembler', 'none') RETURNING id
),

eval_image_type_ AS (
	INSERT INTO image_type (name, description)
	VALUES ('assembly_evaluation', 'none') RETURNING id
),

product_image_instance_ AS (
	INSERT INTO image_instance (image_type_id, name, sha256, active)
	VALUES((SELECT id FROM product_image_type_), 'bioboxes/velvet', '1234567890abcdef', true) RETURNING id
),

image_instance_task_ AS (
	INSERT INTO image_instance_task (image_instance_id, task, active)
	VALUES((SELECT id FROM product_image_instance_), 'default', true) RETURNING id
),

data_set_ AS (
	INSERT INTO data_set (name, description, active)
	VALUES('example data', 'none', true) RETURNING id
),

data_record_ AS (
	INSERT INTO data_record (data_set_id, entry_id, replicate, reads, input_url, reference_url, input_md5, reference_md5, active)
	VALUES((SELECT id FROM data_set_), 1, 1, 200000, 's3://url', 's3://url', 'abcedf', 'abcedf', true) RETURNING id
),

benchmark_type_ AS (
	INSERT INTO benchmark_type (name, product_image_type_id, evaluation_image_type_id, active)
	VALUES('benchmark',
		(SELECT id FROM product_image_type_),
		(SELECT id FROM eval_image_type_),
		true) RETURNING id
),

benchmark_instance_ AS (
	INSERT INTO benchmark_instance (external_id, benchmark_type_id, data_record_id, product_image_instance_task_id)
	VALUES('abcdef',
		(SELECT id FROM benchmark_type_),
		(SELECT id FROM data_record_),
		(SELECT id FROM image_instance_task_)
	) RETURNING id
)
INSERT INTO task (benchmark_instance_id, image_instance_task_id, task_type)
VALUES ((SELECT id FROM image_instance_task_),
	(SELECT id FROM image_instance_task_),
	'produce')
