-- Setup result tables and sequence

SET search_path = fdc_administration, public;

DROP TABLE IF EXISTS patches_done;

CREATE TABLE IF NOT EXISTS patches_done
(
    patch_name character varying NOT NULL,
    long_name character varying NOT NULL DEFAULT '',
    created timestamp,
    run_at timestamp,
    CONSTRAINT patches_done_pkey PRIMARY KEY (patch_name)
);
