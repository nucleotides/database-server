INSERT INTO input_data_file_set (
  name,
  description,
  platform_type_id,
  product_type_id,
  protocol_type_id,
  run_mode_type_id,
  input_data_source_id
)
VALUES (
  'jgi_isolate_microbe_2x150_1',
  'desc',
  (SELECT id FROM platform_type WHERE name = 'illumina'),
  (SELECT id FROM product_type WHERE name = 'random'),
  (SELECT id FROM run_mode_type WHERE name = '2x150_270'),
  (SELECT id FROM protocol_type WHERE name = 'nextera'),
  (SELECT id FROM input_data_source WHERE name = 'ecoli_k12')
)
