WITH events AS (
	INSERT INTO event (task_id, success)
	     SELECT task_id, true
               FROM task_expanded_fields
              WHERE external_id = '0eef178216b7ace8a00f4a255076d6af'
	        AND image_task IN ('sleep', 'eat_penguin')
           ORDER BY task_id ASC
          RETURNING task_id, event_id
)
INSERT INTO metric_instance (event_id, metric_type_id, value)
     SELECT event_id, metric_type_id, 43200
       FROM events
       JOIN task_expanded_fields USING (task_id)
 CROSS JOIN metric_type
      WHERE (image_task = 'sleep'       AND metric_type.name = 'total_wall_clock_time_in_seconds')
         OR (image_task = 'sleep'       AND metric_type.name = 'total_cpu_usage_in_seconds')
         OR (image_task = 'eat_penguin' AND metric_type.name = 'produce_task_metric_1')
   ORDER BY event_id, metric_type_id ASC
