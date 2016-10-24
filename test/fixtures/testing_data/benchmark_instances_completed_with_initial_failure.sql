WITH events_ AS (
	INSERT INTO event (task_id, success)
	     SELECT task_id, false
	       FROM task
	       JOIN benchmark_instance USING (benchmark_instance_id)
	       JOIN image_task ON image_task.image_task_id = product_image_task_id
	      WHERE image_task.name = 'image_1_task_1'
	        AND benchmark_instance.input_data_file_id = 2
          RETURNING task_id, event_id
)
INSERT INTO metric_instance (event_id, metric_type_id, value)
     SELECT event_id, metric_type_id, 0
       FROM events_
       JOIN task USING (task_id)
 CROSS JOIN (SELECT metric_type_id
	       FROM metric_type
	      WHERE name = 'metric_1') AS m
      WHERE task_type = 'produce';
--;;
WITH events_ AS (
	INSERT INTO event (task_id, success)
	     SELECT task_id, true
	       FROM task
	       JOIN benchmark_instance USING (benchmark_instance_id)
	       JOIN image_task ON image_task.image_task_id = product_image_task_id
	      WHERE image_task.name = 'image_1_task_1'
          RETURNING task_id, event_id
)
INSERT INTO metric_instance (event_id, metric_type_id, value)
     SELECT event_id, metric_type_id, 1
       FROM events_
       JOIN task USING (task_id)
 CROSS JOIN (SELECT metric_type_id
	       FROM metric_type
	      WHERE name = 'metric_1') AS m
      WHERE task_type = 'produce';
