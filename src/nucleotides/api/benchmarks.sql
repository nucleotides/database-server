-- name: benchmarks
-- Get all benchmark entries
SELECT * FROM benchmark_instance_status;

-- name: benchmarks-by-product
-- Get all benchmark entries by product status
SELECT * FROM benchmark_instance_status WHERE product = :product;

-- name: benchmarks-by-eval
-- Get all benchmark entries by evaluation status
SELECT * FROM benchmark_instance_status WHERE evaluation = :evaluation;
