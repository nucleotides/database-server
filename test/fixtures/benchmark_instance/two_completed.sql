--
-- The aim of this feature is to complete and add multiple different types of
-- metrics for two benchmark instances.
--
--;;
WITH events AS (
	INSERT INTO event (task_id, success)
	     SELECT task_id, true
               FROM task_expanded_fields
              WHERE external_id in ('6151f5ab282d90e4cee404433b271dda', 'b425e0c75591aa8fcea1aeb2e03b5944')
           ORDER BY task_id ASC
          RETURNING task_id, event_id
)
INSERT INTO metric_instance (event_id, metric_type_id, value)
     SELECT event_id, metric_type_id, 1
       FROM events
       JOIN task_expanded_fields USING (task_id)
 CROSS JOIN metric_type
      WHERE (image_task = 'sleep'       AND metric_type.name = 'evaluate_task_metric_1')
         OR (image_task = 'chase_sheep' AND metric_type.name = 'evaluate_task_metric_2')
         OR (task_type  = 'produce'     AND metric_type.name = 'produce_task_metric_1')
   ORDER BY event_id, metric_type_id ASC
