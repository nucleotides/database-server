-- name: metrics
-- Fetches all rows from completed benchmark metrics
SELECT * FROM completed_benchmark_metrics;

-- name: metrics-by-benchmark-type
-- Fetches all rows from completed benchmark metrics subsetting by benchmark name
SELECT *
  FROM completed_benchmark_metrics
 WHERE benchmark_type_name IN (:benchmark_type);

-- name: metrics-by-variable-name
-- Fetches all rows from completed benchmark metrics subsetting by variable name
SELECT *
  FROM completed_benchmark_metrics
 WHERE variable IN (:variable);

-- name: metrics-by-variable-and-benchmark-name
-- Fetches all rows from completed benchmark metrics subsetting by variable name
SELECT *
  FROM completed_benchmark_metrics
 WHERE variable            IN (:variable)
   AND benchmark_type_name IN (:benchmark_type);
