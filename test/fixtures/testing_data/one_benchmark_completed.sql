--
-- The aim of this feature is to simulate multiple different types of
-- completed metrics for a single benchmark, where the same metrics
-- may have been submitted multiple times for the same task.
--
--;;
WITH fixtures AS (
	SELECT * FROM
	(VALUES ('0eef178216b7ace8a00f4a255076d6af', 'sleep',         'evaluate_task_metric_1'),
	        ('0eef178216b7ace8a00f4a255076d6af', 'chase_sheep',   'evaluate_task_metric_2'),
	        ('0eef178216b7ace8a00f4a255076d6af', 'eat_penguin',   'produce_task_metric_1')) AS metrics
	        (external_id,                        image_task,  metric_type_name)
),
events AS (
INSERT INTO event (task_id, success)
     SELECT task_id, true
       FROM task_expanded_fields
       JOIN fixtures USING (external_id, image_task)
  RETURNING event_id, task_id
)
INSERT INTO metric_instance (event_id, metric_type_id, value)
     SELECT event_id, metric_type_id, 1
       FROM events
       JOIN task_expanded_fields USING (task_id)
       JOIN fixtures             USING (image_task, external_id)
       JOIN metric_type           ON (metric_type_name = metric_type.name)
   ORDER BY event_id, metric_type_id
