WITH failed_events AS (
	INSERT INTO event (task_id, success)
	     SELECT task_id, false
               FROM task_expanded_fields
              WHERE external_id = '0eef178216b7ace8a00f4a255076d6af'
                AND task_type = 'produce'
           ORDER BY task_id ASC
          RETURNING task_id, event_id, success
),
successful_events AS (
	INSERT INTO event (task_id, success)
	     SELECT task_id, true
               FROM task_expanded_fields
              WHERE external_id = '0eef178216b7ace8a00f4a255076d6af'
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
