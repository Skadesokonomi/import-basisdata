-- Setup result tables and sequence

SET search_path = fdc_results, public;

DROP VIEW IF EXISTS batches_view;
DROP VIEW IF EXISTS models_view;
DROP VIEW IF EXISTS parameters_view;
DROP VIEW IF EXISTS used_parameters_view;

DROP TABLE IF EXISTS used_parameters;
DROP TABLE IF EXISTS used_models;
DROP TABLE IF EXISTS batches;
DROP SEQUENCE IF EXISTS id_numbers;

CREATE SEQUENCE IF NOT EXISTS id_numbers;

CREATE TABLE IF NOT EXISTS batches
(
    bid bigint NOT NULL DEFAULT nextval('fdc_results.id_numbers'),
    name character varying NOT NULL,
    run_at timestamp,
    no_models INT default 0,
    CONSTRAINT batches_pkey PRIMARY KEY (bid)
);

CREATE TABLE fdc_results.used_models
(
    mid bigint NOT NULL DEFAULT nextval('fdc_results.id_numbers'::regclass),
    bid bigint NOT NULL,
    table_name character varying COLLATE pg_catalog."default" NOT NULL,
    name character varying COLLATE pg_catalog."default" NOT NULL,
    no_rows integer,
    no_secs double precision,
    CONSTRAINT used_models_pkey PRIMARY KEY (mid)
);


CREATE TABLE IF NOT EXISTS used_parameters
(
    uid bigint NOT NULL DEFAULT nextval('fdc_results.id_numbers'),
    mid bigint NOT NULL,
    name character varying COLLATE pg_catalog."default" NOT NULL,
    value character varying COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT used_parameters_pkey PRIMARY KEY (uid)
);


CREATE OR REPLACE VIEW used_parameters_view
 AS
 SELECT b.bid,
    b.name AS "Batch name",
    b.run_at::varchar AS "Creation time",
    b.no_models AS "Number of models",
    m.mid,
    m.table_name AS "Table name",
    m.name AS "Model name",
    m.no_rows AS "Number of rows",
    m.no_secs::NUMERIC(6,2) AS "Number of seconds",
    p.uid,
    p.name AS "Parameter name",
    p.value AS "Parameter value"
   FROM batches b
     LEFT JOIN used_models m ON b.bid = m.bid
     LEFT JOIN used_parameters p ON m.mid = p.mid
  ORDER BY b.bid, m.mid, p.uid;

CREATE OR REPLACE VIEW batches_view
 AS
 SELECT bid, "Batch name", "Number of models", "Creation time" FROM used_parameters_view GROUP BY 1,2,3,4;

CREATE OR REPLACE VIEW models_view
 AS
 SELECT bid, mid, "Model name", "Number of rows", "Number of seconds" FROM used_parameters_view GROUP BY 1,2,3,4,5;

CREATE OR REPLACE VIEW parameters_view
 AS
 SELECT mid, uid, "Parameter name", "Parameter value" FROM used_parameters_view GROUP BY 1,2,3,4;