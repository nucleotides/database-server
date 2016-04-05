INSERT INTO input_data_file_set (
  name,
  description,
  platform_type_id,
  protocol_type_id,
  run_mode_type_id,
  biological_source_id
)
VALUES (
  'jgi_microbe_00001',
  'desc',
  (SELECT id FROM platform_type WHERE name = 'miseq'),
  (SELECT id FROM run_mode_type WHERE name = '2x150_300'),
  (SELECT id FROM protocol_type WHERE name = 'regular_fragment'),
  (SELECT id FROM biological_source WHERE name = 'amycolatopsis_sulphurea_dsm_46092'))
