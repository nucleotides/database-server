CREATE OR REPLACE FUNCTION create_file_instance(digest TEXT, file_name TEXT, file_url TEXT)
RETURNS integer AS $$
  INSERT INTO file_instance (file_type_id, sha256, url)
  SELECT (SELECT id FROM file_type WHERE name = $2 LIMIT 1), $1, $3
  ON CONFLICT DO NOTHING;
  SELECT id FROM file_instance WHERE sha256 = $1
$$ LANGUAGE SQL;
