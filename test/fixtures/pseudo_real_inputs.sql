--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.2
-- Dumped by pg_dump version 9.5.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgres; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: task_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE task_type AS ENUM (
    'produce',
    'evaluate'
);


ALTER TYPE task_type OWNER TO postgres;

--
-- Name: benchmark_instance_external_id(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION benchmark_instance_external_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	NEW.external_id := md5(NEW.benchmark_type_id || '-' || NEW.input_data_file_id || '-' || NEW.product_image_task_id);
	RETURN NEW;
END;$$;


ALTER FUNCTION public.benchmark_instance_external_id() OWNER TO postgres;

--
-- Name: create_file_instance(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION create_file_instance(digest text, file_name text, file_url text) RETURNS integer
    LANGUAGE sql
    AS $_$
INSERT INTO file_instance (file_type_id, sha256, url)
SELECT (SELECT file_type_id FROM file_type WHERE name = $2 LIMIT 1), $1, $3
ON CONFLICT DO NOTHING;
SELECT file_instance_id FROM file_instance WHERE sha256 = $1
$_$;


ALTER FUNCTION public.create_file_instance(digest text, file_name text, file_url text) OWNER TO postgres;

--
-- Name: create_foreign_key(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION create_foreign_key(src character varying, dst character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$
BEGIN
EXECUTE format('
ALTER TABLE %1$s
ADD CONSTRAINT %4$s FOREIGN KEY (%2$s)
REFERENCES %3$s (%2$s)
', src, dst || '_id', dst, src || '_to_' || dst || '_fkey');
END
$_$;


ALTER FUNCTION public.create_foreign_key(src character varying, dst character varying) OWNER TO postgres;

--
-- Name: create_metadata_table(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION create_metadata_table(metadata_name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
EXECUTE format('
CREATE TABLE IF NOT EXISTS %I (
id		serial		PRIMARY KEY,
created_at	timestamp	DEFAULT current_timestamp,
name	text		UNIQUE NOT NULL,
description	text		NOT NULL,
active	bool		NOT NULL DEFAULT true
);', metadata_name || '_type');
END
$$;


ALTER FUNCTION public.create_metadata_table(metadata_name character varying) OWNER TO postgres;

--
-- Name: populate_benchmark_instance(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION populate_benchmark_instance() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
INSERT INTO benchmark_instance(
	benchmark_type_id,
	product_image_task_id,
	input_data_file_id,
	file_instance_id)
SELECT
benchmark_type_id,
image_task_id,
input_data_file_id,
file_instance_id
FROM benchmark_type
INNER JOIN benchmark_data                            USING (benchmark_type_id)
INNER JOIN image_expanded_fields           AS images ON images.image_type_id = benchmark_type.product_image_type_id
INNER JOIN input_data_file_expanded_fields AS inputs USING (input_data_file_set_id)
ORDER BY benchmark_type_id, input_data_file_id, image_instance_id, image_task_id ASC
ON CONFLICT DO NOTHING;
END; $$;


ALTER FUNCTION public.populate_benchmark_instance() OWNER TO postgres;

--
-- Name: populate_task(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION populate_task() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
INSERT INTO task (benchmark_instance_id, image_task_id, task_type)
	SELECT
	benchmark_instance_id,
	images.image_task_id,
	'evaluate'::task_type AS task_type
	FROM benchmark_instance
	INNER JOIN benchmark_type                  USING (benchmark_type_id)
	INNER JOIN image_expanded_fields AS images ON images.image_type_id = benchmark_type.evaluation_image_type_id
UNION
	SELECT
	benchmark_instance_id,
	benchmark_instance.product_image_task_id AS image_task_id,
	'produce'::task_type                     AS task_type
	FROM benchmark_instance
EXCEPT
	SELECT
	benchmark_instance_id,
	image_task_id,
	task_type
	FROM task
ORDER BY benchmark_instance_id, image_task_id, task_type ASC;
END; $$;


ALTER FUNCTION public.populate_task() OWNER TO postgres;

--
-- Name: rebuild_benchmarks(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rebuild_benchmarks() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
REFRESH MATERIALIZED VIEW input_data_file_expanded_fields;
REFRESH MATERIALIZED VIEW image_expanded_fields;
PERFORM populate_benchmark_instance();
PERFORM populate_task();
REINDEX TABLE benchmark_instance;
REINDEX TABLE task;
END; $$;


ALTER FUNCTION public.rebuild_benchmarks() OWNER TO postgres;

--
-- Name: rename_primary_key(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rename_primary_key(table_name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$
BEGIN
EXECUTE format('
ALTER TABLE %1$s DROP CONSTRAINT %2$s cascade;
ALTER TABLE %1$s RENAME COLUMN id TO %3$s;
ALTER TABLE %1$s ADD PRIMARY KEY (%3$s);
', table_name, table_name || '_pkey', table_name || '_id');
END
$_$;


ALTER FUNCTION public.rename_primary_key(table_name character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: benchmark_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE benchmark_data (
    benchmark_data_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    input_data_file_set_id integer NOT NULL,
    benchmark_type_id integer NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE benchmark_data OWNER TO postgres;

--
-- Name: benchmark_data_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE benchmark_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE benchmark_data_id_seq OWNER TO postgres;

--
-- Name: benchmark_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE benchmark_data_id_seq OWNED BY benchmark_data.benchmark_data_id;


--
-- Name: benchmark_instance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE benchmark_instance (
    benchmark_instance_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    external_id text NOT NULL,
    benchmark_type_id integer NOT NULL,
    input_data_file_id integer NOT NULL,
    product_image_task_id integer NOT NULL,
    file_instance_id integer NOT NULL
);


ALTER TABLE benchmark_instance OWNER TO postgres;

--
-- Name: benchmark_instance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE benchmark_instance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE benchmark_instance_id_seq OWNER TO postgres;

--
-- Name: benchmark_instance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE benchmark_instance_id_seq OWNED BY benchmark_instance.benchmark_instance_id;


--
-- Name: benchmark_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE benchmark_type (
    benchmark_type_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    product_image_type_id integer NOT NULL,
    evaluation_image_type_id integer NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE benchmark_type OWNER TO postgres;

--
-- Name: biological_source; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE biological_source (
    biological_source_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    description text NOT NULL,
    active boolean DEFAULT true NOT NULL,
    source_type_id integer NOT NULL
);


ALTER TABLE biological_source OWNER TO postgres;

--
-- Name: extraction_method_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE extraction_method_type (
    extraction_method_type_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    description text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE extraction_method_type OWNER TO postgres;

--
-- Name: file_instance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE file_instance (
    file_instance_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    file_type_id integer NOT NULL,
    sha256 text NOT NULL,
    url text NOT NULL
);


ALTER TABLE file_instance OWNER TO postgres;

--
-- Name: file_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE file_type (
    file_type_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    description text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE file_type OWNER TO postgres;

--
-- Name: image_instance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE image_instance (
    image_instance_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    image_type_id integer NOT NULL,
    name text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE image_instance OWNER TO postgres;

--
-- Name: image_task; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE image_task (
    image_task_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    image_version_id integer NOT NULL,
    name text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE image_task OWNER TO postgres;

--
-- Name: image_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE image_type (
    image_type_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    description text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE image_type OWNER TO postgres;

--
-- Name: image_version; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE image_version (
    image_version_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    image_instance_id integer NOT NULL,
    name text NOT NULL,
    sha256 text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE image_version OWNER TO postgres;

--
-- Name: image_expanded_fields; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW image_expanded_fields AS
 SELECT image_type.image_type_id,
    image_instance.image_instance_id,
    image_version.image_version_id,
    image_task.image_task_id,
    image_type.created_at AS image_type_created_at,
    image_instance.created_at AS image_instance_created_at,
    image_version.created_at AS image_version_created_at,
    image_task.created_at AS image_task_created_at,
    image_type.name AS image_type_name,
    image_instance.name AS image_instance_name,
    image_version.name AS image_version_name,
    image_version.sha256 AS image_version_sha256,
    image_task.name AS image_task_name
   FROM (((image_type
     JOIN image_instance USING (image_type_id))
     JOIN image_version USING (image_instance_id))
     JOIN image_task USING (image_version_id))
  WITH NO DATA;


ALTER TABLE image_expanded_fields OWNER TO postgres;

--
-- Name: input_data_file; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE input_data_file (
    input_data_file_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL,
    input_data_file_set_id integer NOT NULL,
    file_instance_id integer NOT NULL
);


ALTER TABLE input_data_file OWNER TO postgres;

--
-- Name: input_data_file_set; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE input_data_file_set (
    input_data_file_set_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    biological_source_id integer NOT NULL,
    platform_type_id integer NOT NULL,
    protocol_type_id integer NOT NULL,
    material_type_id integer NOT NULL,
    extraction_method_type_id integer NOT NULL,
    run_mode_type_id integer NOT NULL
);


ALTER TABLE input_data_file_set OWNER TO postgres;

--
-- Name: material_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE material_type (
    material_type_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    description text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE material_type OWNER TO postgres;

--
-- Name: platform_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE platform_type (
    platform_type_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    description text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE platform_type OWNER TO postgres;

--
-- Name: protocol_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE protocol_type (
    protocol_type_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    description text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE protocol_type OWNER TO postgres;

--
-- Name: run_mode_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE run_mode_type (
    run_mode_type_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    description text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE run_mode_type OWNER TO postgres;

--
-- Name: source_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE source_type (
    source_type_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    description text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE source_type OWNER TO postgres;

--
-- Name: input_data_file_expanded_fields; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW input_data_file_expanded_fields AS
 SELECT input_data_file.file_instance_id,
    file_instance.file_type_id,
    input_data_file.input_data_file_set_id,
    input_data_file.input_data_file_id,
    input_data_file_set.biological_source_id,
    input_data_file_set.platform_type_id,
    input_data_file_set.protocol_type_id,
    input_data_file_set.material_type_id,
    input_data_file_set.extraction_method_type_id,
    input_data_file_set.run_mode_type_id,
    file_instance.created_at AS file_instance_created_at,
    input_data_file_set.created_at AS input_file_set_created_at,
    input_data_file.created_at AS input_file_created_at,
    file_type.name AS file_type,
    platform_type.name AS platform,
    protocol_type.name AS protocol,
    material_type.name AS material,
    extraction_method_type.name AS extraction_method,
    run_mode_type.name AS run_mode,
    source_type.name AS biological_source_type,
    biological_source.name AS biological_source_name,
    input_data_file_set.name AS input_file_set_name,
    input_data_file_set.active AS input_file_set_active,
    input_data_file.active AS input_file_active,
    biological_source.active AS biological_source_active,
    file_instance.sha256,
    file_instance.url
   FROM ((((((((((input_data_file
     JOIN file_instance USING (file_instance_id))
     JOIN input_data_file_set USING (input_data_file_set_id))
     JOIN biological_source USING (biological_source_id))
     JOIN source_type USING (source_type_id))
     JOIN file_type USING (file_type_id))
     JOIN platform_type USING (platform_type_id))
     JOIN protocol_type USING (protocol_type_id))
     JOIN material_type USING (material_type_id))
     JOIN extraction_method_type USING (extraction_method_type_id))
     JOIN run_mode_type USING (run_mode_type_id))
  WITH NO DATA;


ALTER TABLE input_data_file_expanded_fields OWNER TO postgres;

--
-- Name: benchmark_instance_name; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW benchmark_instance_name AS
 SELECT benchmark_instance.benchmark_instance_id,
    ((((((((((((benchmark_type.name || ' '::text) || images.image_instance_name) || '/'::text) || images.image_version_name) || '/'::text) || images.image_task_name) || ' '::text) || inputs.biological_source_name) || '/'::text) || inputs.input_file_set_name) || '/'::text) || inputs.sha256) AS name
   FROM (((benchmark_instance
     JOIN benchmark_type USING (benchmark_type_id))
     JOIN image_expanded_fields images ON ((images.image_task_id = benchmark_instance.product_image_task_id)))
     JOIN input_data_file_expanded_fields inputs USING (file_instance_id));


ALTER TABLE benchmark_instance_name OWNER TO postgres;

--
-- Name: benchmark_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE benchmark_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE benchmark_type_id_seq OWNER TO postgres;

--
-- Name: benchmark_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE benchmark_type_id_seq OWNED BY benchmark_type.benchmark_type_id;


--
-- Name: biological_source_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE biological_source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE biological_source_id_seq OWNER TO postgres;

--
-- Name: biological_source_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE biological_source_id_seq OWNED BY biological_source.biological_source_id;


--
-- Name: biological_source_input_data_file_set; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW biological_source_input_data_file_set AS
 SELECT input_data_file_set.input_data_file_set_id,
    input_data_file_set.biological_source_id,
    input_data_file_set.name AS input_data_file_set_name,
    biological_source.name AS biological_source_name
   FROM (input_data_file_set
     JOIN biological_source USING (biological_source_id));


ALTER TABLE biological_source_input_data_file_set OWNER TO postgres;

--
-- Name: biological_source_reference_file; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE biological_source_reference_file (
    biological_source_reference_file_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL,
    biological_source_id integer NOT NULL,
    file_instance_id integer NOT NULL
);


ALTER TABLE biological_source_reference_file OWNER TO postgres;

--
-- Name: biological_source_reference_file_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE biological_source_reference_file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE biological_source_reference_file_id_seq OWNER TO postgres;

--
-- Name: biological_source_reference_file_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE biological_source_reference_file_id_seq OWNED BY biological_source_reference_file.biological_source_reference_file_id;


--
-- Name: db_version; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE db_version (
    id bigint NOT NULL
);


ALTER TABLE db_version OWNER TO postgres;

--
-- Name: event; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE event (
    event_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    task_id integer NOT NULL,
    success boolean NOT NULL
);


ALTER TABLE event OWNER TO postgres;

--
-- Name: event_file_instance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE event_file_instance (
    event_file_instance_id integer NOT NULL,
    event_id integer NOT NULL,
    file_instance_id integer NOT NULL
);


ALTER TABLE event_file_instance OWNER TO postgres;

--
-- Name: event_file_instance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE event_file_instance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE event_file_instance_id_seq OWNER TO postgres;

--
-- Name: event_file_instance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE event_file_instance_id_seq OWNED BY event_file_instance.event_file_instance_id;


--
-- Name: event_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE event_id_seq OWNER TO postgres;

--
-- Name: event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE event_id_seq OWNED BY event.event_id;


--
-- Name: events_prioritised_by_successful; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW events_prioritised_by_successful AS
 SELECT DISTINCT ON (event.task_id) event.event_id,
    event.created_at,
    event.task_id,
    event.success
   FROM event
  ORDER BY event.task_id, event.success DESC, event.created_at;


ALTER TABLE events_prioritised_by_successful OWNER TO postgres;

--
-- Name: extraction_method_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE extraction_method_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE extraction_method_type_id_seq OWNER TO postgres;

--
-- Name: extraction_method_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE extraction_method_type_id_seq OWNED BY extraction_method_type.extraction_method_type_id;


--
-- Name: file_instance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE file_instance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE file_instance_id_seq OWNER TO postgres;

--
-- Name: file_instance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE file_instance_id_seq OWNED BY file_instance.file_instance_id;


--
-- Name: file_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE file_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE file_type_id_seq OWNER TO postgres;

--
-- Name: file_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE file_type_id_seq OWNED BY file_type.file_type_id;


--
-- Name: image_instance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE image_instance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE image_instance_id_seq OWNER TO postgres;

--
-- Name: image_instance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE image_instance_id_seq OWNED BY image_instance.image_instance_id;


--
-- Name: image_task_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE image_task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE image_task_id_seq OWNER TO postgres;

--
-- Name: image_task_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE image_task_id_seq OWNED BY image_task.image_task_id;


--
-- Name: image_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE image_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE image_type_id_seq OWNER TO postgres;

--
-- Name: image_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE image_type_id_seq OWNED BY image_type.image_type_id;


--
-- Name: image_version_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE image_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE image_version_id_seq OWNER TO postgres;

--
-- Name: image_version_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE image_version_id_seq OWNED BY image_version.image_version_id;


--
-- Name: input_data_file_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE input_data_file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE input_data_file_id_seq OWNER TO postgres;

--
-- Name: input_data_file_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE input_data_file_id_seq OWNED BY input_data_file.input_data_file_id;


--
-- Name: input_data_file_set_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE input_data_file_set_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE input_data_file_set_id_seq OWNER TO postgres;

--
-- Name: input_data_file_set_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE input_data_file_set_id_seq OWNED BY input_data_file_set.input_data_file_set_id;


--
-- Name: material_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE material_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE material_type_id_seq OWNER TO postgres;

--
-- Name: material_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE material_type_id_seq OWNED BY material_type.material_type_id;


--
-- Name: metric_instance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE metric_instance (
    metric_instance_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    metric_type_id integer NOT NULL,
    event_id integer NOT NULL,
    value double precision NOT NULL
);


ALTER TABLE metric_instance OWNER TO postgres;

--
-- Name: metric_instance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE metric_instance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metric_instance_id_seq OWNER TO postgres;

--
-- Name: metric_instance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE metric_instance_id_seq OWNED BY metric_instance.metric_instance_id;


--
-- Name: metric_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE metric_type (
    metric_type_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    description text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE metric_type OWNER TO postgres;

--
-- Name: metric_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE metric_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metric_type_id_seq OWNER TO postgres;

--
-- Name: metric_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE metric_type_id_seq OWNED BY metric_type.metric_type_id;


--
-- Name: platform_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE platform_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE platform_type_id_seq OWNER TO postgres;

--
-- Name: platform_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE platform_type_id_seq OWNED BY platform_type.platform_type_id;


--
-- Name: protocol_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE protocol_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE protocol_type_id_seq OWNER TO postgres;

--
-- Name: protocol_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE protocol_type_id_seq OWNED BY protocol_type.protocol_type_id;


--
-- Name: run_mode_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE run_mode_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE run_mode_type_id_seq OWNER TO postgres;

--
-- Name: run_mode_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE run_mode_type_id_seq OWNED BY run_mode_type.run_mode_type_id;


--
-- Name: source_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE source_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE source_type_id_seq OWNER TO postgres;

--
-- Name: source_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE source_type_id_seq OWNED BY source_type.source_type_id;


--
-- Name: task; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE task (
    task_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    benchmark_instance_id integer NOT NULL,
    image_task_id integer NOT NULL,
    task_type task_type NOT NULL
);


ALTER TABLE task OWNER TO postgres;

--
-- Name: task_expanded_fields; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW task_expanded_fields AS
 SELECT task.task_id,
    task.benchmark_instance_id,
    benchmark_instance.external_id,
    task.task_type,
    images.image_instance_name AS image_name,
    images.image_version_name AS image_version,
    images.image_version_sha256 AS image_sha256,
    images.image_task_name AS image_task,
    images.image_type_name AS image_type,
    COALESCE(events.success, false) AS complete
   FROM (((task
     LEFT JOIN image_expanded_fields images USING (image_task_id))
     LEFT JOIN benchmark_instance USING (benchmark_instance_id))
     LEFT JOIN events_prioritised_by_successful events USING (task_id));


ALTER TABLE task_expanded_fields OWNER TO postgres;

--
-- Name: task_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE task_id_seq OWNER TO postgres;

--
-- Name: task_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE task_id_seq OWNED BY task.task_id;


--
-- Name: benchmark_data_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_data ALTER COLUMN benchmark_data_id SET DEFAULT nextval('benchmark_data_id_seq'::regclass);


--
-- Name: benchmark_instance_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_instance ALTER COLUMN benchmark_instance_id SET DEFAULT nextval('benchmark_instance_id_seq'::regclass);


--
-- Name: benchmark_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_type ALTER COLUMN benchmark_type_id SET DEFAULT nextval('benchmark_type_id_seq'::regclass);


--
-- Name: biological_source_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY biological_source ALTER COLUMN biological_source_id SET DEFAULT nextval('biological_source_id_seq'::regclass);


--
-- Name: biological_source_reference_file_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY biological_source_reference_file ALTER COLUMN biological_source_reference_file_id SET DEFAULT nextval('biological_source_reference_file_id_seq'::regclass);


--
-- Name: event_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY event ALTER COLUMN event_id SET DEFAULT nextval('event_id_seq'::regclass);


--
-- Name: event_file_instance_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY event_file_instance ALTER COLUMN event_file_instance_id SET DEFAULT nextval('event_file_instance_id_seq'::regclass);


--
-- Name: extraction_method_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY extraction_method_type ALTER COLUMN extraction_method_type_id SET DEFAULT nextval('extraction_method_type_id_seq'::regclass);


--
-- Name: file_instance_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file_instance ALTER COLUMN file_instance_id SET DEFAULT nextval('file_instance_id_seq'::regclass);


--
-- Name: file_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file_type ALTER COLUMN file_type_id SET DEFAULT nextval('file_type_id_seq'::regclass);


--
-- Name: image_instance_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_instance ALTER COLUMN image_instance_id SET DEFAULT nextval('image_instance_id_seq'::regclass);


--
-- Name: image_task_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_task ALTER COLUMN image_task_id SET DEFAULT nextval('image_task_id_seq'::regclass);


--
-- Name: image_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_type ALTER COLUMN image_type_id SET DEFAULT nextval('image_type_id_seq'::regclass);


--
-- Name: image_version_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_version ALTER COLUMN image_version_id SET DEFAULT nextval('image_version_id_seq'::regclass);


--
-- Name: input_data_file_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY input_data_file ALTER COLUMN input_data_file_id SET DEFAULT nextval('input_data_file_id_seq'::regclass);


--
-- Name: input_data_file_set_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY input_data_file_set ALTER COLUMN input_data_file_set_id SET DEFAULT nextval('input_data_file_set_id_seq'::regclass);


--
-- Name: material_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY material_type ALTER COLUMN material_type_id SET DEFAULT nextval('material_type_id_seq'::regclass);


--
-- Name: metric_instance_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY metric_instance ALTER COLUMN metric_instance_id SET DEFAULT nextval('metric_instance_id_seq'::regclass);


--
-- Name: metric_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY metric_type ALTER COLUMN metric_type_id SET DEFAULT nextval('metric_type_id_seq'::regclass);


--
-- Name: platform_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY platform_type ALTER COLUMN platform_type_id SET DEFAULT nextval('platform_type_id_seq'::regclass);


--
-- Name: protocol_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY protocol_type ALTER COLUMN protocol_type_id SET DEFAULT nextval('protocol_type_id_seq'::regclass);


--
-- Name: run_mode_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY run_mode_type ALTER COLUMN run_mode_type_id SET DEFAULT nextval('run_mode_type_id_seq'::regclass);


--
-- Name: source_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY source_type ALTER COLUMN source_type_id SET DEFAULT nextval('source_type_id_seq'::regclass);


--
-- Name: task_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY task ALTER COLUMN task_id SET DEFAULT nextval('task_id_seq'::regclass);


--
-- Data for Name: benchmark_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO benchmark_data VALUES (1, '2016-10-17 22:24:46.815583', 2, 1, true);
INSERT INTO benchmark_data VALUES (2, '2016-10-17 22:24:46.819188', 1, 2, true);


--
-- Name: benchmark_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('benchmark_data_id_seq', 2, true);


--
-- Data for Name: benchmark_instance; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO benchmark_instance VALUES (1, '2016-10-17 22:24:46.821596', '6151f5ab282d90e4cee404433b271dda', 1, 2, 1, 4);
INSERT INTO benchmark_instance VALUES (2, '2016-10-17 22:24:46.821596', 'e61730e6717b1787cf09d44914ffb920', 1, 2, 2, 4);
INSERT INTO benchmark_instance VALUES (3, '2016-10-17 22:24:46.821596', 'b425e0c75591aa8fcea1aeb2e03b5944', 1, 3, 1, 5);
INSERT INTO benchmark_instance VALUES (4, '2016-10-17 22:24:46.821596', 'bc5861c5c13a0b0659a923b6b51a3878', 1, 3, 2, 5);
INSERT INTO benchmark_instance VALUES (5, '2016-10-17 22:24:46.821596', '2bfadbf90d1c59921977d7f7dad69239', 2, 1, 3, 3);
INSERT INTO benchmark_instance VALUES (6, '2016-10-17 22:24:46.821596', '0eef178216b7ace8a00f4a255076d6af', 2, 1, 6, 3);


--
-- Name: benchmark_instance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('benchmark_instance_id_seq', 6, true);


--
-- Data for Name: benchmark_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO benchmark_type VALUES (1, '2016-10-17 22:24:46.792347', 'benchmark_1', 'desc', 1, 2, true);
INSERT INTO benchmark_type VALUES (2, '2016-10-17 22:24:46.795738', 'benchmark_2', 'desc', 3, 2, true);
INSERT INTO benchmark_type VALUES (3, '2016-10-17 22:24:46.797989', 'empty', 'desc', 4, 4, true);


--
-- Name: benchmark_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('benchmark_type_id_seq', 3, true);


--
-- Data for Name: biological_source; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO biological_source VALUES (1, '2016-10-17 22:24:46.752236', 'bad_camel_case_source2', 'desc', true, 2);
INSERT INTO biological_source VALUES (2, '2016-10-17 22:24:46.75546', 'source_1', 'desc', true, 2);


--
-- Name: biological_source_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('biological_source_id_seq', 2, true);


--
-- Data for Name: biological_source_reference_file; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO biological_source_reference_file VALUES (1, '2016-10-17 22:24:46.758663', true, 1, 1);
INSERT INTO biological_source_reference_file VALUES (2, '2016-10-17 22:24:46.761952', true, 2, 2);


--
-- Name: biological_source_reference_file_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('biological_source_reference_file_id_seq', 2, true);


--
-- Data for Name: db_version; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO db_version VALUES (2015101019150000);
INSERT INTO db_version VALUES (2016083110010000);
INSERT INTO db_version VALUES (2016101110190000);
INSERT INTO db_version VALUES (2016101215300000);


--
-- Data for Name: event; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: event_file_instance; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: event_file_instance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('event_file_instance_id_seq', 1, false);


--
-- Name: event_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('event_id_seq', 1, false);


--
-- Data for Name: extraction_method_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO extraction_method_type VALUES (1, '2016-10-17 22:24:46.57185', 'cultured_colony_isolate', 'DNA extracted from a single colony', true);
INSERT INTO extraction_method_type VALUES (2, '2016-10-17 22:24:46.57295', 'multiple_displacement_amplification', 'DNA extracted from random priming and amplification', true);
INSERT INTO extraction_method_type VALUES (3, '2016-10-17 22:24:46.575993', 'environmental_sample', 'DNA extracted from a mixed environmental sample', true);


--
-- Name: extraction_method_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('extraction_method_type_id_seq', 3, true);


--
-- Data for Name: file_instance; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO file_instance VALUES (1, '2016-10-17 22:24:46.758663', 4, 'reference_2_digest', 's3://data_set_2_url_1');
INSERT INTO file_instance VALUES (2, '2016-10-17 22:24:46.761952', 4, 'reference_1_digest', 's3://data_set_1_url_1');
INSERT INTO file_instance VALUES (3, '2016-10-17 22:24:46.774911', 3, 'data_set_2_data_1_digest_1', 's3://data_set_2_url_2');
INSERT INTO file_instance VALUES (4, '2016-10-17 22:24:46.778229', 3, 'data_set_1_data_1_digest_1', 's3://data_set_1_url_2');
INSERT INTO file_instance VALUES (5, '2016-10-17 22:24:46.789393', 3, 'data_set_1_data_1_digest_2', 's3://data_set_1_url_3');


--
-- Name: file_instance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('file_instance_id_seq', 5, true);


--
-- Data for Name: file_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO file_type VALUES (1, '2016-10-17 22:24:46.629139', 'container_log', 'Free form text output produced by the container being benchmarked', true);
INSERT INTO file_type VALUES (2, '2016-10-17 22:24:46.630911', 'container_runtime_metrics', 'Runtime metrics collected while running the Docker container', true);
INSERT INTO file_type VALUES (3, '2016-10-17 22:24:46.631699', 'short_read_fastq', 'Short read sequences in FASTQ format', true);
INSERT INTO file_type VALUES (4, '2016-10-17 22:24:46.632424', 'reference_fasta', 'Reference sequence in FASTA format', true);
INSERT INTO file_type VALUES (5, '2016-10-17 22:24:46.633179', 'contig_fasta', 'Reads assembled into larger contiguous sequences in FASTA format', true);
INSERT INTO file_type VALUES (6, '2016-10-17 22:24:46.634003', 'assembly_metrics', 'Quast genome assembly metrics file', true);


--
-- Name: file_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('file_type_id_seq', 6, true);


--
-- Data for Name: image_instance; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO image_instance VALUES (1, '2016-10-17 22:24:46.679047', 1, 'image_1', true);
INSERT INTO image_instance VALUES (3, '2016-10-17 22:24:46.712785', 3, 'image_2', true);
INSERT INTO image_instance VALUES (4, '2016-10-17 22:24:46.718356', 2, 'image_3', true);
INSERT INTO image_instance VALUES (6, '2016-10-17 22:24:46.744965', 3, 'image_4', true);


--
-- Name: image_instance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('image_instance_id_seq', 6, true);


--
-- Data for Name: image_task; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO image_task VALUES (1, '2016-10-17 22:24:46.700973', 1, 'image_1_task_1', true);
INSERT INTO image_task VALUES (2, '2016-10-17 22:24:46.708953', 2, 'image_1_task_2', true);
INSERT INTO image_task VALUES (3, '2016-10-17 22:24:46.716289', 3, 'image_2_task', true);
INSERT INTO image_task VALUES (4, '2016-10-17 22:24:46.721929', 4, 'image_3_task_1', true);
INSERT INTO image_task VALUES (5, '2016-10-17 22:24:46.73978', 4, 'image_3_task_2', true);
INSERT INTO image_task VALUES (6, '2016-10-17 22:24:46.748205', 6, 'image_4_task', true);


--
-- Name: image_task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('image_task_id_seq', 6, true);


--
-- Data for Name: image_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO image_type VALUES (1, '2016-10-17 22:24:46.561731', 'image_type_1', 'dummy', true);
INSERT INTO image_type VALUES (2, '2016-10-17 22:24:46.562863', 'image_type_2', 'dummy', true);
INSERT INTO image_type VALUES (3, '2016-10-17 22:24:46.564044', 'image_type_3', 'dummy', true);
INSERT INTO image_type VALUES (4, '2016-10-17 22:24:46.568676', 'non_existing_image', 'dummy', true);


--
-- Name: image_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('image_type_id_seq', 4, true);


--
-- Data for Name: image_version; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO image_version VALUES (1, '2016-10-17 22:24:46.694494', 1, 'v1.1', 'image_1_digest_1', true);
INSERT INTO image_version VALUES (2, '2016-10-17 22:24:46.706702', 1, 'v1.2', 'image_1_digest_2', true);
INSERT INTO image_version VALUES (3, '2016-10-17 22:24:46.714657', 3, 'v2', 'image_2_digest', true);
INSERT INTO image_version VALUES (4, '2016-10-17 22:24:46.720283', 4, 'v3', 'image_3_digest', true);
INSERT INTO image_version VALUES (6, '2016-10-17 22:24:46.746709', 6, 'v4', 'image_4_digest', true);


--
-- Name: image_version_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('image_version_id_seq', 6, true);


--
-- Data for Name: input_data_file; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO input_data_file VALUES (1, '2016-10-17 22:24:46.774911', true, 1, 3);
INSERT INTO input_data_file VALUES (2, '2016-10-17 22:24:46.778229', true, 2, 4);
INSERT INTO input_data_file VALUES (3, '2016-10-17 22:24:46.789393', true, 2, 5);


--
-- Name: input_data_file_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('input_data_file_id_seq', 3, true);


--
-- Data for Name: input_data_file_set; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO input_data_file_set VALUES (1, '2016-10-17 22:24:46.76629', true, 'data_set_2_data_1', 'desc', 1, 1, 1, 1, 1, 2);
INSERT INTO input_data_file_set VALUES (2, '2016-10-17 22:24:46.770385', true, 'data_set_1_data_1', 'desc', 2, 1, 1, 1, 1, 2);


--
-- Name: input_data_file_set_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('input_data_file_set_id_seq', 2, true);


--
-- Data for Name: material_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO material_type VALUES (1, '2016-10-17 22:24:46.637795', 'dna', 'Deoxyribonucleic acid', true);
INSERT INTO material_type VALUES (2, '2016-10-17 22:24:46.638897', 'rna', 'Ribonucleic acid', true);


--
-- Name: material_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('material_type_id_seq', 2, true);


--
-- Data for Name: metric_instance; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: metric_instance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('metric_instance_id_seq', 1, false);


--
-- Data for Name: metric_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO metric_type VALUES (1, '2016-10-17 22:24:46.579065', 'total_wall_clock_time_in_seconds', 'Actual time taken from starting the Docker container until it completes', true);
INSERT INTO metric_type VALUES (2, '2016-10-17 22:24:46.581416', 'max_memory_usage', 'Memory usage when running the producing Docker container', true);
INSERT INTO metric_type VALUES (3, '2016-10-17 22:24:46.582238', 'max_cpu_usage', 'CPU usage when running the producing Docker container', true);
INSERT INTO metric_type VALUES (4, '2016-10-17 22:24:46.583071', 'duplication_ratio', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (5, '2016-10-17 22:24:46.583919', 'indels_per_100_kbp', 'Number of insertions and deletions per 100kbp', true);
INSERT INTO metric_type VALUES (6, '2016-10-17 22:24:46.584819', 'l50', 'A number of sequences at which sum of lengths exceeds 50%', true);
INSERT INTO metric_type VALUES (7, '2016-10-17 22:24:46.585626', 'l75', 'A number of sequences at which sum of lengths exceeds 75%', true);
INSERT INTO metric_type VALUES (8, '2016-10-17 22:24:46.586534', 'la50', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (9, '2016-10-17 22:24:46.587342', 'la75', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (10, '2016-10-17 22:24:46.588502', 'largest_alignment', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (11, '2016-10-17 22:24:46.589333', 'largest_contig', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (12, '2016-10-17 22:24:46.590141', 'lg50', 'L50 normalised by reference genome length', true);
INSERT INTO metric_type VALUES (13, '2016-10-17 22:24:46.590975', 'lg75', 'LG50 normalised by reference genome length', true);
INSERT INTO metric_type VALUES (14, '2016-10-17 22:24:46.591791', 'lga50', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (15, '2016-10-17 22:24:46.592623', 'lga75', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (16, '2016-10-17 22:24:46.593442', 'misassembled_contigs_length', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (17, '2016-10-17 22:24:46.594248', 'mismatches_per_100_kbp', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (18, '2016-10-17 22:24:46.597014', 'n50', 'Length of sequences at which sum of lengths exceeds 50%', true);
INSERT INTO metric_type VALUES (19, '2016-10-17 22:24:46.597908', 'n75', 'Length of sequences at which sum of lengths exceeds 75%', true);
INSERT INTO metric_type VALUES (20, '2016-10-17 22:24:46.598774', 'n_contigs_gt_0', 'Number of contigs', true);
INSERT INTO metric_type VALUES (21, '2016-10-17 22:24:46.599618', 'n_contigs_gt_1000', 'Number of contigs greater than 1,000bp', true);
INSERT INTO metric_type VALUES (22, '2016-10-17 22:24:46.600462', 'n_contigs_gt_5000', 'Number of contigs greater than 5,000bp', true);
INSERT INTO metric_type VALUES (23, '2016-10-17 22:24:46.60131', 'n_contigs_gt_10000', 'Number of contigs greater than 10,000bp', true);
INSERT INTO metric_type VALUES (24, '2016-10-17 22:24:46.60214', 'n_contigs_gt_25000', 'Number of contigs greater than 25,000bp', true);
INSERT INTO metric_type VALUES (25, '2016-10-17 22:24:46.602972', 'n_contigs_gt_50000', 'Number of contigs greater than 50,000bp', true);
INSERT INTO metric_type VALUES (26, '2016-10-17 22:24:46.603809', 'n_local_misassemblies', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (27, '2016-10-17 22:24:46.604636', 'n_misassemblies', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (28, '2016-10-17 22:24:46.605474', 'n_per_100_kbp', 'Number of Ns per 100kbp', true);
INSERT INTO metric_type VALUES (29, '2016-10-17 22:24:46.608236', 'na50', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (30, '2016-10-17 22:24:46.609126', 'na75', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (31, '2016-10-17 22:24:46.609976', 'ng50', 'N50 normalised by reference genome length', true);
INSERT INTO metric_type VALUES (32, '2016-10-17 22:24:46.610811', 'ng75', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (33, '2016-10-17 22:24:46.612516', 'nga50', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (34, '2016-10-17 22:24:46.613356', 'nga75', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (35, '2016-10-17 22:24:46.614199', 'perc_gc', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (36, '2016-10-17 22:24:46.61507', 'perc_genome_fraction', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (37, '2016-10-17 22:24:46.615937', 'perc_ref_gc', 'Percent GC for reference sequence', true);
INSERT INTO metric_type VALUES (38, '2016-10-17 22:24:46.616802', 'reference_length', 'Length of reference sequence', true);
INSERT INTO metric_type VALUES (39, '2016-10-17 22:24:46.61764', 'total_length_gt_0', 'Number of contigs', true);
INSERT INTO metric_type VALUES (40, '2016-10-17 22:24:46.618479', 'total_length_gt_1000', 'Sum of contig lengths greather than 1kbp', true);
INSERT INTO metric_type VALUES (41, '2016-10-17 22:24:46.619334', 'total_length_gt_10000', 'Sum of contig lengths greather than 10kbp', true);
INSERT INTO metric_type VALUES (42, '2016-10-17 22:24:46.620248', 'total_length_gt_25000', 'Sum of contig lengths greather than 25kbp', true);
INSERT INTO metric_type VALUES (43, '2016-10-17 22:24:46.621101', 'total_length_gt_5000', 'Sum of contig lengths greather than 5kbp', true);
INSERT INTO metric_type VALUES (44, '2016-10-17 22:24:46.621954', 'total_length_gt_50000', 'Sum of contig lengths greather than 50kbp', true);
INSERT INTO metric_type VALUES (45, '2016-10-17 22:24:46.622786', 'unaligned_length', 'A Quast assembly metric', true);
INSERT INTO metric_type VALUES (46, '2016-10-17 22:24:46.627476', 'n_misassembled_contigs', 'Number of missambled contigs', true);


--
-- Name: metric_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('metric_type_id_seq', 46, true);


--
-- Data for Name: platform_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO platform_type VALUES (1, '2016-10-17 22:24:46.634903', 'miseq', 'A desktop sequencer produced by Illumina', true);
INSERT INTO platform_type VALUES (2, '2016-10-17 22:24:46.635983', 'nextseq', 'A desktop sequencer produced by Illumina', true);
INSERT INTO platform_type VALUES (3, '2016-10-17 22:24:46.636894', 'hiseq_2500_rapid', 'A high-throughput sequencer produced by Illumina', true);


--
-- Name: platform_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('platform_type_id_seq', 3, true);


--
-- Data for Name: protocol_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO protocol_type VALUES (1, '2016-10-17 22:24:46.559035', 'unamplified_regular_fragment', 'Standard preparation when source material is available in sufficient quantities', true);
INSERT INTO protocol_type VALUES (2, '2016-10-17 22:24:46.56073', 'nextera_amplified_fragment', 'Amplification of source material when available in small quantities', true);


--
-- Name: protocol_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('protocol_type_id_seq', 2, true);


--
-- Data for Name: run_mode_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO run_mode_type VALUES (1, '2016-10-17 22:24:46.569854', '2x150_270', 'An insert size of 270bp sequenced with 2x150bp reads', true);
INSERT INTO run_mode_type VALUES (2, '2016-10-17 22:24:46.570884', '2x150_300', 'An insert size of 300bp sequenced with 2x150bp reads', true);


--
-- Name: run_mode_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('run_mode_type_id_seq', 2, true);


--
-- Data for Name: source_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO source_type VALUES (1, '2016-10-17 22:24:46.577081', 'metagenome', 'A mixture of multiple genomes', true);
INSERT INTO source_type VALUES (2, '2016-10-17 22:24:46.578123', 'microbe', 'A single isolated microbe', true);


--
-- Name: source_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('source_type_id_seq', 2, true);


--
-- Data for Name: task; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO task VALUES (1, '2016-10-17 22:24:46.821596', 1, 1, 'produce');
INSERT INTO task VALUES (2, '2016-10-17 22:24:46.821596', 1, 4, 'evaluate');
INSERT INTO task VALUES (3, '2016-10-17 22:24:46.821596', 1, 5, 'evaluate');
INSERT INTO task VALUES (4, '2016-10-17 22:24:46.821596', 2, 2, 'produce');
INSERT INTO task VALUES (5, '2016-10-17 22:24:46.821596', 2, 4, 'evaluate');
INSERT INTO task VALUES (6, '2016-10-17 22:24:46.821596', 2, 5, 'evaluate');
INSERT INTO task VALUES (7, '2016-10-17 22:24:46.821596', 3, 1, 'produce');
INSERT INTO task VALUES (8, '2016-10-17 22:24:46.821596', 3, 4, 'evaluate');
INSERT INTO task VALUES (9, '2016-10-17 22:24:46.821596', 3, 5, 'evaluate');
INSERT INTO task VALUES (10, '2016-10-17 22:24:46.821596', 4, 2, 'produce');
INSERT INTO task VALUES (11, '2016-10-17 22:24:46.821596', 4, 4, 'evaluate');
INSERT INTO task VALUES (12, '2016-10-17 22:24:46.821596', 4, 5, 'evaluate');
INSERT INTO task VALUES (13, '2016-10-17 22:24:46.821596', 5, 3, 'produce');
INSERT INTO task VALUES (14, '2016-10-17 22:24:46.821596', 5, 4, 'evaluate');
INSERT INTO task VALUES (15, '2016-10-17 22:24:46.821596', 5, 5, 'evaluate');
INSERT INTO task VALUES (16, '2016-10-17 22:24:46.821596', 6, 4, 'evaluate');
INSERT INTO task VALUES (17, '2016-10-17 22:24:46.821596', 6, 5, 'evaluate');
INSERT INTO task VALUES (18, '2016-10-17 22:24:46.821596', 6, 6, 'produce');


--
-- Name: task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('task_id_seq', 18, true);


--
-- Name: benchmark_data_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_data
    ADD CONSTRAINT benchmark_data_idx UNIQUE (input_data_file_set_id, benchmark_type_id);


--
-- Name: benchmark_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_data
    ADD CONSTRAINT benchmark_data_pkey PRIMARY KEY (benchmark_data_id);


--
-- Name: benchmark_instance_external_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_instance
    ADD CONSTRAINT benchmark_instance_external_id_key UNIQUE (external_id);


--
-- Name: benchmark_instance_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_instance
    ADD CONSTRAINT benchmark_instance_idx UNIQUE (benchmark_type_id, input_data_file_id, product_image_task_id);


--
-- Name: benchmark_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_instance
    ADD CONSTRAINT benchmark_instance_pkey PRIMARY KEY (benchmark_instance_id);


--
-- Name: benchmark_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_type
    ADD CONSTRAINT benchmark_type_name_key UNIQUE (name);


--
-- Name: benchmark_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_type
    ADD CONSTRAINT benchmark_type_pkey PRIMARY KEY (benchmark_type_id);


--
-- Name: biological_source_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY biological_source
    ADD CONSTRAINT biological_source_name_key UNIQUE (name);


--
-- Name: biological_source_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY biological_source
    ADD CONSTRAINT biological_source_pkey PRIMARY KEY (biological_source_id);


--
-- Name: biological_source_reference_file_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY biological_source_reference_file
    ADD CONSTRAINT biological_source_reference_file_pkey PRIMARY KEY (biological_source_reference_file_id);


--
-- Name: db_version_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY db_version
    ADD CONSTRAINT db_version_id_key UNIQUE (id);


--
-- Name: event_file_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY event_file_instance
    ADD CONSTRAINT event_file_idx UNIQUE (event_id, file_instance_id);


--
-- Name: event_file_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY event_file_instance
    ADD CONSTRAINT event_file_instance_pkey PRIMARY KEY (event_file_instance_id);


--
-- Name: event_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY event
    ADD CONSTRAINT event_pkey PRIMARY KEY (event_id);


--
-- Name: extraction_method_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY extraction_method_type
    ADD CONSTRAINT extraction_method_type_name_key UNIQUE (name);


--
-- Name: extraction_method_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY extraction_method_type
    ADD CONSTRAINT extraction_method_type_pkey PRIMARY KEY (extraction_method_type_id);


--
-- Name: file_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file_instance
    ADD CONSTRAINT file_instance_pkey PRIMARY KEY (file_instance_id);


--
-- Name: file_instance_sha256_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file_instance
    ADD CONSTRAINT file_instance_sha256_key UNIQUE (sha256);


--
-- Name: file_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file_type
    ADD CONSTRAINT file_type_name_key UNIQUE (name);


--
-- Name: file_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file_type
    ADD CONSTRAINT file_type_pkey PRIMARY KEY (file_type_id);


--
-- Name: image_instance_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_instance
    ADD CONSTRAINT image_instance_name_key UNIQUE (name);


--
-- Name: image_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_instance
    ADD CONSTRAINT image_instance_pkey PRIMARY KEY (image_instance_id);


--
-- Name: image_name_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_version
    ADD CONSTRAINT image_name_idx UNIQUE (image_instance_id, name);


--
-- Name: image_task_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_task
    ADD CONSTRAINT image_task_idx UNIQUE (image_version_id, name);


--
-- Name: image_task_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_task
    ADD CONSTRAINT image_task_pkey PRIMARY KEY (image_task_id);


--
-- Name: image_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_type
    ADD CONSTRAINT image_type_name_key UNIQUE (name);


--
-- Name: image_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_type
    ADD CONSTRAINT image_type_pkey PRIMARY KEY (image_type_id);


--
-- Name: image_version_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_version
    ADD CONSTRAINT image_version_pkey PRIMARY KEY (image_version_id);


--
-- Name: image_version_sha256_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_version
    ADD CONSTRAINT image_version_sha256_key UNIQUE (sha256);


--
-- Name: input_data_file_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY input_data_file
    ADD CONSTRAINT input_data_file_pkey PRIMARY KEY (input_data_file_id);


--
-- Name: input_data_file_set_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY input_data_file_set
    ADD CONSTRAINT input_data_file_set_pkey PRIMARY KEY (input_data_file_set_id);


--
-- Name: material_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY material_type
    ADD CONSTRAINT material_type_name_key UNIQUE (name);


--
-- Name: material_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY material_type
    ADD CONSTRAINT material_type_pkey PRIMARY KEY (material_type_id);


--
-- Name: metric_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY metric_instance
    ADD CONSTRAINT metric_instance_pkey PRIMARY KEY (metric_instance_id);


--
-- Name: metric_to_event; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY metric_instance
    ADD CONSTRAINT metric_to_event UNIQUE (metric_type_id, event_id);


--
-- Name: metric_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY metric_type
    ADD CONSTRAINT metric_type_name_key UNIQUE (name);


--
-- Name: metric_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY metric_type
    ADD CONSTRAINT metric_type_pkey PRIMARY KEY (metric_type_id);


--
-- Name: platform_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY platform_type
    ADD CONSTRAINT platform_type_name_key UNIQUE (name);


--
-- Name: platform_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY platform_type
    ADD CONSTRAINT platform_type_pkey PRIMARY KEY (platform_type_id);


--
-- Name: protocol_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY protocol_type
    ADD CONSTRAINT protocol_type_name_key UNIQUE (name);


--
-- Name: protocol_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY protocol_type
    ADD CONSTRAINT protocol_type_pkey PRIMARY KEY (protocol_type_id);


--
-- Name: run_mode_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY run_mode_type
    ADD CONSTRAINT run_mode_type_name_key UNIQUE (name);


--
-- Name: run_mode_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY run_mode_type
    ADD CONSTRAINT run_mode_type_pkey PRIMARY KEY (run_mode_type_id);


--
-- Name: source_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY source_type
    ADD CONSTRAINT source_type_name_key UNIQUE (name);


--
-- Name: source_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY source_type
    ADD CONSTRAINT source_type_pkey PRIMARY KEY (source_type_id);


--
-- Name: task_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY task
    ADD CONSTRAINT task_idx UNIQUE (benchmark_instance_id, image_task_id, task_type);


--
-- Name: task_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY task
    ADD CONSTRAINT task_pkey PRIMARY KEY (task_id);


--
-- Name: unique_file_per_file_set_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY input_data_file
    ADD CONSTRAINT unique_file_per_file_set_idx UNIQUE (input_data_file_set_id, file_instance_id);


--
-- Name: unique_files_set_per_source_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY input_data_file_set
    ADD CONSTRAINT unique_files_set_per_source_idx UNIQUE (name, biological_source_id);


--
-- Name: unique_reference_files_per_source_idx; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY biological_source_reference_file
    ADD CONSTRAINT unique_reference_files_per_source_idx UNIQUE (biological_source_id, file_instance_id);


--
-- Name: event_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX event_status ON event USING btree (success);


--
-- Name: image_expanded_fields_image_instance_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX image_expanded_fields_image_instance_id_idx ON image_expanded_fields USING btree (image_instance_id);


--
-- Name: image_expanded_fields_image_task_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX image_expanded_fields_image_task_id_idx ON image_expanded_fields USING btree (image_task_id);


--
-- Name: image_expanded_fields_image_type_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX image_expanded_fields_image_type_id_idx ON image_expanded_fields USING btree (image_type_id);


--
-- Name: image_expanded_fields_image_type_id_image_instance_id_image_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX image_expanded_fields_image_type_id_image_instance_id_image_idx ON image_expanded_fields USING btree (image_type_id, image_instance_id, image_version_id, image_task_id);


--
-- Name: image_expanded_fields_image_version_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX image_expanded_fields_image_version_id_idx ON image_expanded_fields USING btree (image_version_id);


--
-- Name: input_data_file_expanded_fields_biological_source_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX input_data_file_expanded_fields_biological_source_id_idx ON input_data_file_expanded_fields USING btree (biological_source_id);


--
-- Name: input_data_file_expanded_fields_extraction_method_type_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX input_data_file_expanded_fields_extraction_method_type_id_idx ON input_data_file_expanded_fields USING btree (extraction_method_type_id);


--
-- Name: input_data_file_expanded_fields_file_instance_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX input_data_file_expanded_fields_file_instance_id_idx ON input_data_file_expanded_fields USING btree (file_instance_id);


--
-- Name: input_data_file_expanded_fields_file_type_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX input_data_file_expanded_fields_file_type_id_idx ON input_data_file_expanded_fields USING btree (file_type_id);


--
-- Name: input_data_file_expanded_fields_input_data_file_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX input_data_file_expanded_fields_input_data_file_id_idx ON input_data_file_expanded_fields USING btree (input_data_file_id);


--
-- Name: input_data_file_expanded_fields_input_data_file_set_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX input_data_file_expanded_fields_input_data_file_set_id_idx ON input_data_file_expanded_fields USING btree (input_data_file_set_id);


--
-- Name: input_data_file_expanded_fields_material_type_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX input_data_file_expanded_fields_material_type_id_idx ON input_data_file_expanded_fields USING btree (material_type_id);


--
-- Name: input_data_file_expanded_fields_platform_type_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX input_data_file_expanded_fields_platform_type_id_idx ON input_data_file_expanded_fields USING btree (platform_type_id);


--
-- Name: input_data_file_expanded_fields_protocol_type_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX input_data_file_expanded_fields_protocol_type_id_idx ON input_data_file_expanded_fields USING btree (protocol_type_id);


--
-- Name: input_data_file_expanded_fields_run_mode_type_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX input_data_file_expanded_fields_run_mode_type_id_idx ON input_data_file_expanded_fields USING btree (run_mode_type_id);


--
-- Name: task_type_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX task_type_idx ON task USING btree (task_type);


--
-- Name: benchmark_instance_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER benchmark_instance_insert BEFORE INSERT OR UPDATE ON benchmark_instance FOR EACH ROW EXECUTE PROCEDURE benchmark_instance_external_id();


--
-- Name: benchmark_data_to_benchmark_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_data
    ADD CONSTRAINT benchmark_data_to_benchmark_type_fkey FOREIGN KEY (benchmark_type_id) REFERENCES benchmark_type(benchmark_type_id);


--
-- Name: benchmark_data_to_input_data_file_set_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_data
    ADD CONSTRAINT benchmark_data_to_input_data_file_set_fkey FOREIGN KEY (input_data_file_set_id) REFERENCES input_data_file_set(input_data_file_set_id);


--
-- Name: benchmark_instance_product_image_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_instance
    ADD CONSTRAINT benchmark_instance_product_image_task_id_fkey FOREIGN KEY (product_image_task_id) REFERENCES image_task(image_task_id);


--
-- Name: benchmark_instance_to_benchmark_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_instance
    ADD CONSTRAINT benchmark_instance_to_benchmark_type_fkey FOREIGN KEY (benchmark_type_id) REFERENCES benchmark_type(benchmark_type_id);


--
-- Name: benchmark_instance_to_input_data_file_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_instance
    ADD CONSTRAINT benchmark_instance_to_input_data_file_fkey FOREIGN KEY (input_data_file_id) REFERENCES input_data_file(input_data_file_id);


--
-- Name: benchmark_type_evaluation_image_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_type
    ADD CONSTRAINT benchmark_type_evaluation_image_type_id_fkey FOREIGN KEY (evaluation_image_type_id) REFERENCES image_type(image_type_id);


--
-- Name: benchmark_type_product_image_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY benchmark_type
    ADD CONSTRAINT benchmark_type_product_image_type_id_fkey FOREIGN KEY (product_image_type_id) REFERENCES image_type(image_type_id);


--
-- Name: biological_source_reference_file_to_biological_source_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY biological_source_reference_file
    ADD CONSTRAINT biological_source_reference_file_to_biological_source_fkey FOREIGN KEY (biological_source_id) REFERENCES biological_source(biological_source_id);


--
-- Name: biological_source_reference_file_to_file_instance_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY biological_source_reference_file
    ADD CONSTRAINT biological_source_reference_file_to_file_instance_fkey FOREIGN KEY (file_instance_id) REFERENCES file_instance(file_instance_id);


--
-- Name: biological_source_to_source_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY biological_source
    ADD CONSTRAINT biological_source_to_source_type_fkey FOREIGN KEY (source_type_id) REFERENCES source_type(source_type_id);


--
-- Name: event_file_instance_to_event_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY event_file_instance
    ADD CONSTRAINT event_file_instance_to_event_fkey FOREIGN KEY (event_id) REFERENCES event(event_id);


--
-- Name: event_file_instance_to_file_instance_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY event_file_instance
    ADD CONSTRAINT event_file_instance_to_file_instance_fkey FOREIGN KEY (file_instance_id) REFERENCES file_instance(file_instance_id);


--
-- Name: event_to_task_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY event
    ADD CONSTRAINT event_to_task_fkey FOREIGN KEY (task_id) REFERENCES task(task_id);


--
-- Name: file_instance_to_file_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file_instance
    ADD CONSTRAINT file_instance_to_file_type_fkey FOREIGN KEY (file_type_id) REFERENCES file_type(file_type_id);


--
-- Name: image_instance_to_image_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_instance
    ADD CONSTRAINT image_instance_to_image_type_fkey FOREIGN KEY (image_type_id) REFERENCES image_type(image_type_id);


--
-- Name: image_task_to_image_version_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_task
    ADD CONSTRAINT image_task_to_image_version_fkey FOREIGN KEY (image_version_id) REFERENCES image_version(image_version_id);


--
-- Name: image_version_to_image_instance_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY image_version
    ADD CONSTRAINT image_version_to_image_instance_fkey FOREIGN KEY (image_instance_id) REFERENCES image_instance(image_instance_id);


--
-- Name: input_data_file_set_to_biological_source_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY input_data_file_set
    ADD CONSTRAINT input_data_file_set_to_biological_source_fkey FOREIGN KEY (biological_source_id) REFERENCES biological_source(biological_source_id);


--
-- Name: input_data_file_set_to_extraction_method_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY input_data_file_set
    ADD CONSTRAINT input_data_file_set_to_extraction_method_type_fkey FOREIGN KEY (extraction_method_type_id) REFERENCES extraction_method_type(extraction_method_type_id);


--
-- Name: input_data_file_set_to_material_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY input_data_file_set
    ADD CONSTRAINT input_data_file_set_to_material_type_fkey FOREIGN KEY (material_type_id) REFERENCES material_type(material_type_id);


--
-- Name: input_data_file_set_to_platform_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY input_data_file_set
    ADD CONSTRAINT input_data_file_set_to_platform_type_fkey FOREIGN KEY (platform_type_id) REFERENCES platform_type(platform_type_id);


--
-- Name: input_data_file_set_to_protocol_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY input_data_file_set
    ADD CONSTRAINT input_data_file_set_to_protocol_type_fkey FOREIGN KEY (protocol_type_id) REFERENCES protocol_type(protocol_type_id);


--
-- Name: input_data_file_set_to_run_mode_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY input_data_file_set
    ADD CONSTRAINT input_data_file_set_to_run_mode_type_fkey FOREIGN KEY (run_mode_type_id) REFERENCES run_mode_type(run_mode_type_id);


--
-- Name: input_data_file_to_file_instance_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY input_data_file
    ADD CONSTRAINT input_data_file_to_file_instance_fkey FOREIGN KEY (file_instance_id) REFERENCES file_instance(file_instance_id);


--
-- Name: input_data_file_to_input_data_file_set_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY input_data_file
    ADD CONSTRAINT input_data_file_to_input_data_file_set_fkey FOREIGN KEY (input_data_file_set_id) REFERENCES input_data_file_set(input_data_file_set_id);


--
-- Name: metric_instance_to_event_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY metric_instance
    ADD CONSTRAINT metric_instance_to_event_fkey FOREIGN KEY (event_id) REFERENCES event(event_id);


--
-- Name: metric_instance_to_metric_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY metric_instance
    ADD CONSTRAINT metric_instance_to_metric_type_fkey FOREIGN KEY (metric_type_id) REFERENCES metric_type(metric_type_id);


--
-- Name: task_to_benchmark_instance_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY task
    ADD CONSTRAINT task_to_benchmark_instance_fkey FOREIGN KEY (benchmark_instance_id) REFERENCES benchmark_instance(benchmark_instance_id);


--
-- Name: task_to_image_task_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY task
    ADD CONSTRAINT task_to_image_task_fkey FOREIGN KEY (image_task_id) REFERENCES image_task(image_task_id);


--
-- Name: image_expanded_fields; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW image_expanded_fields;


--
-- Name: input_data_file_expanded_fields; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW input_data_file_expanded_fields;


--
-- PostgreSQL database dump complete
--

