--;;
--;; Docker images
--;;
CREATE TABLE image_type(
  id		serial 		PRIMARY KEY,
  created_at	timestamp	DEFAULT current_timestamp,
  name          text            UNIQUE NOT NULL,
  description	text		NOT NULL
);
--;;
CREATE TABLE image_instance(
  id		serial 		PRIMARY KEY,
  created_at	timestamp	DEFAULT current_timestamp,
  image_type_id	integer		NOT NULL REFERENCES image_type(id),
  name		text	        NOT NULL,
  sha256	text 		NOT NULL,
  active	bool 		NOT NULL
  CONSTRAINT image UNIQUE(image_type_id, name, sha256)
);
--;;
CREATE TABLE image_instance_task(
  id			serial 		PRIMARY KEY,
  created_at		timestamp	DEFAULT current_timestamp,
  image_instance_id	integer		NOT NULL REFERENCES image_instance(id),
  task			text 		NOT NULL,
  active		bool 		NOT NULL
  CONSTRAINT image UNIQUE(image_instance_id, task)
);
