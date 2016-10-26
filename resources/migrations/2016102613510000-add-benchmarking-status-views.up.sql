--;;
--;; Status view of the benchmarking database
--;;
CREATE VIEW benchmark_task_status AS
SELECT
COALESCE(task_type::text, 'all')                                                                            AS task_type,
COUNT(task_id)                                                                                              AS n,
COUNT(task_id) filter (where event.event_id IS NULL)                                                        AS n_outstanding,
COUNT(task_id) filter (where event.event_id IS NOT NULL)                                                    AS n_executed,
COUNT(task_id) filter (where event.success = true)                                                          AS n_successful,
COUNT(task_id) filter (where event.success = false)                                                         AS n_errorful,
round((COUNT(task_id) filter (where event.event_id IS NULL) / COUNT(task_id)::float)::numeric, 4) * 100     AS percent_outstanding,
round((COUNT(task_id) filter (where event.event_id IS NOT NULL) / COUNT(task_id)::float)::numeric, 4) * 100 AS percent_executed,
round((COUNT(task_id) filter (where event.success = true) / COUNT(task_id)::float)::numeric, 4) * 100       AS percent_successful,
round((COUNT(task_id) filter (where event.success = false) / COUNT(task_id)::float)::numeric, 4) * 100      AS percent_errorful,
MAX(event.created_at)                                                                                       AS date_of_most_recent
FROM task
LEFT JOIN events_prioritised_by_successful                                                                  AS event USING (task_id)
GROUP BY ROLLUP(task_type);
