--
-- The aim of this feature is to simulate multiple different types of
-- completed metrics for a single benchmark, where the same metrics
-- may have been submitted multiple times for the same task.
--
--;;
WITH duplicate_events AS (
	INSERT INTO event (task_id, success)
	     SELECT task_id, true
               FROM (SELECT * FROM task_expanded_fields UNION ALL SELECT * FROM task_expanded_fields) as t
              WHERE external_id = '0eef178216b7ace8a00f4a255076d6af'
           ORDER BY task_id ASC
          RETURNING task_id, event_id
)
INSERT INTO metric_instance (event_id, metric_type_id, value)
     SELECT event_id, metric_type_id, 1
       FROM duplicate_events
       JOIN task_expanded_fields USING (task_id)
 CROSS JOIN metric_type
      WHERE (image_task = 'sleep'       AND metric_type.name = 'evaluate_task_metric_1')
         OR (image_task = 'chase_sheep' AND metric_type.name = 'evaluate_task_metric_2')
         OR (image_task = 'eat_penguin' AND metric_type.name = 'produce_task_metric_1')
   ORDER BY event_id, metric_type_id ASC
