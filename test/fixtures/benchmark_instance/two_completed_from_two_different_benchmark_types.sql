--
-- This fixture creates the situation where two benchmarking instances has been
-- succesfully completed. These benchmark are have been completed from two different
-- benchmark types.
--
WITH events AS (
	INSERT INTO event (task_id, success)
	     SELECT task_id, true
               FROM task_expanded_fields
              WHERE external_id in ('bc5861c5c13a0b0659a923b6b51a3878', '52f1e7dbda96ef4b11a66a63476ac076')
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
