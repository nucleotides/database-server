--
-- This fixture creates the situation where one benchmarking task has been
-- succesfully completed, and another has failed. Both of these success and failure
-- events are attached to the same image_task.
--

WITH tasks AS (
     SELECT task_id, task_type, external_id
       FROM benchmark_instance
       JOIN image_expanded_fields ON benchmark_instance.product_image_task_id = image_task_id
       JOIN task                  USING (benchmark_instance_id)
      WHERE image_task_name = 'eat_cow'
   ORDER BY task_id ASC
),
failed_events AS (
	INSERT INTO event (task_id, success)
	     SELECT task_id, false
               FROM tasks
              WHERE external_id = '6151f5ab282d90e4cee404433b271dda'
                AND task_type = 'produce'
           ORDER BY task_id ASC
          RETURNING task_id, event_id, success
),
successful_events AS (
	INSERT INTO event (task_id, success)
	     SELECT task_id, true
               FROM task_expanded_fields
              WHERE external_id = 'b425e0c75591aa8fcea1aeb2e03b5944'
           ORDER BY task_id ASC
          RETURNING task_id, event_id, success
)
INSERT INTO metric_instance (event_id, metric_type_id, value)
     SELECT event_id, metric_type_id, 1
       FROM (
	 SELECT * FROM failed_events
	  UNION
	 SELECT * FROM successful_events) AS events
       JOIN task_expanded_fields USING (task_id)
 CROSS JOIN metric_type
      WHERE (task_type  = 'produce'     AND metric_type.name = 'produce_task_metric_1')
         OR (image_task = 'sleep'       AND metric_type.name = 'evaluate_task_metric_1' AND events.success = true)
         OR (image_task = 'chase_sheep' AND metric_type.name = 'evaluate_task_metric_2' AND events.success = true)
   ORDER BY event_id, metric_type_id ASC
