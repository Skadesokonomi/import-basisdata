
-- Script to setup TGV schemas, tables and functions.

-- Setup PostGIS

CREATE EXTENSION IF NOT EXISTS postgis;

-- Schemas

DROP SCHEMA IF EXISTS tgv_data CASCADE;
DROP SCHEMA IF EXISTS tgv_import CASCADE;
DROP SCHEMA IF EXISTS tgv_functions CASCADE;

CREATE SCHEMA tgv_data; -- schema for data to TGV models
CREATE SCHEMA tgv_import; -- TGV import data
CREATE SCHEMA tgv_functions; -- TGV functions

-- Schema tgv_data tables 

SET search_path = tgv_data, public;

-- Table parameter_groups

CREATE TABLE tgv_parameter_groups (
    parameter_id character varying NOT NULL,
    parameter_values jsonb
);
ALTER TABLE tgv_parameter_groups ADD PRIMARY KEY (parameter_id);

INSERT INTO tgv_parameter_groups (parameter_id, parameter_values) VALUES (
'default',
'{
"name":"default",
"cell_size":100.0,
"epsg_code":25832,
"ydp":180,
"mut1": -1.0,
"mut2": -2.0,
"s1": 652.00,
"s2": 84.00,
"s3": 84.00,
"year_start": 2025,
"year_end": 2124,
"v0": 0,
"v7": 7,
"v30": 30,
"v180": 180,
"year_start_measure": 1990,
"year_end_measure": 2019
}'
);

CREATE TABLE tgv_projects (
    project_id character varying NOT NULL,
    geom Geometry(Multipolygon,25832) NOT NULL -- Assign the correct EPSG code
);
ALTER TABLE tgv_projects ADD PRIMARY KEY (project_id);
CREATE INDEX sidx_tgv_projects_geom ON tgv_projects USING gist(geom);



CREATE TABLE tgv_models (
    project_id character varying NOT NULL,
    model_id character varying NOT NULL,
    parameter_id character varying NOT NULL,
    original boolean NOT NULL DEFAULT FALSE
);
ALTER TABLE tgv_models ADD PRIMARY KEY (project_id,model_id);
ALTER TABLE tgv_models ADD CONSTRAINT fk_tgv_models_projects 
    FOREIGN KEY (project_id) REFERENCES tgv_projects (project_id)
    ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE tgv_models ADD CONSTRAINT fk_tgv_models_parameter_groups 
    FOREIGN KEY (parameter_id) REFERENCES tgv_parameter_groups (parameter_id)
    ON UPDATE CASCADE ON DELETE CASCADE;


CREATE TABLE tgv_cells (
    project_id character varying NOT NULL,
    cell_no bigint NOT NULL,
    spring real,
    summer real,
    autumn real,
    winter real,
    geom Geometry(Multipolygon,25832) NOT NULL
);
ALTER TABLE tgv_cells ADD PRIMARY KEY (project_id,cell_no);
ALTER TABLE tgv_cells ADD CONSTRAINT fk_tgv_cells_projects 
    FOREIGN KEY (project_id) REFERENCES tgv_projects (project_id)
    ON UPDATE CASCADE ON DELETE CASCADE;
CREATE INDEX sidx_tgv_cells_geom ON tgv_cells USING gist(geom);


CREATE TABLE tgv_cell_values (
    project_id character varying NOT NULL,
    model_id character varying NOT NULL,
    cell_no bigint NOT NULL,
    date_stamp date NOT NULL,
    pdate_stamp date,
    depth real 
);
ALTER TABLE tgv_cell_values ADD PRIMARY KEY (project_id,model_id,cell_no,date_stamp);
ALTER TABLE tgv_cell_values ADD CONSTRAINT fk_tgv_cell_values_models 
    FOREIGN KEY (project_id,model_id) REFERENCES tgv_models (project_id,model_id)
    ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE tgv_cell_values ADD CONSTRAINT fk_tgv_cell_values_cells 
    FOREIGN KEY (project_id,cell_no) REFERENCES tgv_cells (project_id,cell_no)
    ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


CREATE TABLE tgv_cell_calculations (
    project_id character varying NOT NULL,
    model_id character varying NOT NULL,
    cell_no bigint NOT NULL,
    year integer NOT NULL CHECK (year >= 1900 AND year <= 2300),
    depths real[],
    days_tot integer,
    days_mut1 integer,
    days_mut2 integer	
);
ALTER TABLE tgv_cell_calculations ADD PRIMARY KEY (project_id,model_id,cell_no,year);
ALTER TABLE tgv_cell_calculations ADD CONSTRAINT fk_tgv_cell_calculations_models 
    FOREIGN KEY (project_id,model_id) REFERENCES tgv_models (project_id,model_id)
    ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE tgv_cell_calculations ADD CONSTRAINT fk_tgv_cell_calculations_cells 
    FOREIGN KEY (project_id,cell_no) REFERENCES tgv_cells (project_id,cell_no)
    ON UPDATE CASCADE ON DELETE CASCADE;


CREATE TABLE tgv_buildings(
    building_id character varying NOT NULL,
	municipality_code integer,
    build_usage_code integer,
	cellar_area_m2 real,
	cellar_perimeter_m real,
	is_protected boolean, 
    geom Geometry(Multipolygon,25832)
);
ALTER TABLE tgv_buildings ADD PRIMARY KEY (building_id);
CREATE INDEX sidx_tgv_buildings_geom ON tgv_buildings USING gist(geom);


CREATE TABLE tgv_building_costs (
    building_id character varying NOT NULL,
    project_id character varying NOT NULL,
    model_id character varying NOT NULL,
    cell_no bigint NOT NULL,
    year integer NOT NULL CHECK (year >= 1900 AND year <= 2300),
    cost numeric(12,2) NOT NULL DEFAULT 0.0 CHECK (cost >= 0.0)   
);
ALTER TABLE tgv_building_costs ADD PRIMARY KEY (building_id,project_id,model_id,cell_no,year);
ALTER TABLE tgv_building_costs ADD CONSTRAINT fk_tgv_building_costs_buildings 
    FOREIGN KEY (building_id) REFERENCES tgv_buildings (building_id)
    ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE tgv_building_costs ADD CONSTRAINT fk_tgv_building_costs_models 
    FOREIGN KEY (project_id,model_id) REFERENCES tgv_models (project_id,model_id)
    ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE tgv_building_costs ADD CONSTRAINT fk_tgv_building_costs_cell_calculations 
    FOREIGN KEY (project_id,model_id,cell_no, year) REFERENCES tgv_cell_calculations (project_id,model_id,cell_no, year)
    ON UPDATE CASCADE ON DELETE CASCADE;

CREATE VIEW tgv_building_costs_sum AS
    WITH c AS (SELECT 
        project_id,
        model_id,
        cell_no,
        MIN(year) AS year_start,
        MAX(year) AS year_end,
        COUNT(year) AS no_years,
        SUM (cost) AS tot_cost        
    FROM tgv_building_costs
    GROUP BY 1,2,3,4
    ) SELECT b.*, c.* FROM tgv_buildings b JOIN c ON b.building_id = c.building_id;

CREATE TABLE IF NOT EXISTS tgv_corrections
(
    project_id character varying COLLATE pg_catalog."default" NOT NULL,
    season character varying COLLATE pg_catalog."default" NOT NULL,
    id bigint NOT NULL,
    depth numeric,
    geom geometry(Polygon,25832),
    CONSTRAINT tgv_corrections_pkey PRIMARY KEY (project_id, season, id)
);
ALTER TABLE tgv_corrections ADD CONSTRAINT fk_tgv_models_projects 
    FOREIGN KEY (project_id) REFERENCES tgv_projects (project_id)
    ON UPDATE CASCADE ON DELETE CASCADE;
CREATE INDEX sidx_tgv_corrections_geom ON tgv_corrections USING gist(geom);


-- helper functions

CREATE OR REPLACE FUNCTION tgv_functions.parameter_groups_exists(parm_name character varying) RETURNS boolean AS $$
    BEGIN 
        RETURN (EXISTS(SELECT 1 FROM tgv_data.tgv_parameter_groups WHERE parameter_id = parm_name)); 
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tgv_functions.projects_exists(proj_name character varying) RETURNS boolean AS $$
    BEGIN 
        RETURN (EXISTS(SELECT 1 FROM tgv_data.tgv_projects WHERE project_id = proj_name)); 
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tgv_functions.models_exists(proj_name character varying, mod_name character varying) RETURNS boolean AS $$
    BEGIN 
        RETURN (EXISTS(SELECT 1 FROM tgv_data.tgv_models WHERE project_id = proj_name AND model_id = mod_name)); 
    END;
$$ LANGUAGE plpgsql;


-- parameter_groups functions

CREATE OR REPLACE FUNCTION tgv_functions.parameter_groups_create(parm_name character varying, parm_block character varying) RETURNS void AS $$
    BEGIN
        IF NOT tgv_functions.parameter_groups_exists(parm_name) THEN  
            INSERT INTO tgv_data.tgv_parameter_groups (parameter_id, parameter_values) VALUES (parm_name, parm_block::jsonb);
        ELSE
            RAISE EXCEPTION 'Duplicate parameter id: %', parm_name USING HINT = 'Choose another id for parameter record';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tgv_functions.parameter_groups_read(parm_name character varying) RETURNS character varying AS $$
    DECLARE
        parm_block jsonb := '{}'::jsonb;
    BEGIN
        IF tgv_functions.parameter_groups_exists(parm_name) THEN 
            SELECT parameter_values INTO parm_block FROM tgv_data.tgv_parameter_groups WHERE parameter_id = parm_name;
        ELSE
            RAISE EXCEPTION 'Non existing parameter id: %', parm_name USING HINT = 'Use another id for parameter record';
        END IF;
        RETURN (parm_block::character varying);
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tgv_functions.parameter_groups_update(parm_name character varying, parm_block character varying DEFAULT '{}', merge boolean DEFAULT true) RETURNS void AS $$
    BEGIN
        IF tgv_functions.parameter_groups_exists(parm_name) THEN 
            IF merge THEN
                UPDATE tgv_data.tgv_parameter_groups SET parameter_values = parameter_values || parm_block::jsonb WHERE parameter_id = parm_name;
            ELSE
                UPDATE tgv_data.tgv_parameter_groups SET parameter_values = parm_block::jsonb WHERE parameter_id = parm_name;
            END iF;
        ELSE
            RAISE EXCEPTION 'Non existing parameter id: %', parm_name USING HINT = 'Use another id for parameter record';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tgv_functions.parameter_groups_delete(parm_name character varying) RETURNS void AS $$
    BEGIN
        IF tgv_functions.parameter_groups_exists(parm_name) THEN 
            DELETE FROM tgv_data.tgv_parameter_groups WHERE parameter_id = parm_name;
        ELSE
            RAISE EXCEPTION 'Non existing parameter id: %', parm_name USING HINT = 'Use another id for parameter record';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tgv_functions.parameter_groups_copy (parm_name character varying, new_name character varying) RETURNS void AS $$
    BEGIN
        IF tgv_functions.parameter_groups_exists(parm_name) THEN 
            IF NOT tgv_functions.parameter_groups_exists(new_name) THEN 
                INSERT INTO tgv_data.tgv_parameter_groups (parameter_id,parameter_values) 
                    SELECT new_name AS parameter_id, parameter_values FROM tgv_data.tgv_parameter_groups WHERE parameter_id = parm_name;
            ELSE
                RAISE EXCEPTION 'Existing parameter id: %', new_name USING HINT = 'Choose another id for new parameter record';
            END IF;
        ELSE
            RAISE EXCEPTION 'Non existing parameter id: %', parm_name USING HINT = 'Use another id for original parameter record';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;


-- project functions

CREATE OR REPLACE FUNCTION tgv_functions.projects_create (proj_name character varying, proj_wkt character varying, proj_srid integer DEFAULT 25832) RETURNS void AS $$ -- Assign the correct EPSG code
    BEGIN
        IF NOT tgv_functions.projects_exists(proj_name) THEN  
            INSERT INTO tgv_data.tgv_projects (project_id, geom) VALUES (proj_name, ST_GeomFromText(proj_wkt, proj_srid));
        ELSE
            RAISE EXCEPTION 'Duplicate project id: %', proj_name USING HINT = 'Choose another id for new project';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tgv_functions.projects_read(proj_name character varying) RETURNS character varying AS $$
    DECLARE
        result jsonb := '{}'::jsonb;

    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN 
            SELECT row_to_json(p) INTO result FROM tgv_data.tgv_projects p WHERE p.project_id = proj_name;            
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Use another id for project to read';
        END IF;
        RETURN (result::character varying);
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tgv_functions.project_update(proj_name character varying, proj_wkt character varying, proj_srid integer DEFAULT 25832) RETURNS void AS $$ -- Assign the correct EPSG code
    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN 
            UPDATE tgv_data.tgv_projects SET geom = ST_GeomFromText(proj_wkt, proj_srid);
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Use another id for project to update';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tgv_functions.projects_delete(proj_name character varying) RETURNS void AS $$
    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN 
            DELETE FROM tgv_data.tgv_projects WHERE parameter_id = proj_name;
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Use another id for project to delete';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tgv_functions.projects_copy (proj_name character varying, new_name character varying, deep_copy boolean DEFAULT false) RETURNS void AS $$
    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN 
            IF NOT tgv_functions.projects_exists(new_name) THEN 
                INSERT INTO tgv_data.tgv_projects SELECT new_name AS project_id, geom FROM tgv_data.tgv_projects WHERE parameter_id = proj_name;
                IF deep_copy THEN
                    INSERT INTO tgv_data.models SELECT new_name AS project_id, model_id, parameter_id, false AS original FROM tgv_data.models WHERE project_id = proj_name;
                    INSERT INTO tgv_data.cells SELECT new_name AS project_id, cell_no,geom FROM tgv_data.cells WHERE project_id = proj_name;
                    INSERT INTO tgv_data.tgv_cell_values SELECT new_name AS project_id,model_id,cell_no,date_stamp,NULL AS pdate_stamp,depth FROM tgv_data.cell_values WHERE project_id = proj_name;
                    INSERT INTO tgv_data.tgv_cell_calculations 
                        SELECT new_name AS project_id,model_id,cell_no,year,depths,days_tot,days_mut1,days_mut2 FROM tgv_data.tgv_cell_calculations WHERE project_id = proj_name;
                    INSERT INTO tgv_data.tgv_building_costs 
                        SELECT new_name AS project_id,building_id,model_id,cell_no,year,cost FROM tgv_data.tgv_building_costs WHERE project_id = proj_name;
                 END IF;
            ELSE
                RAISE EXCEPTION 'Existing project id: %', new_name USING HINT = 'Choose another id for new project';
            END IF;
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Choose another id for original project';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;

-- model functions

CREATE OR REPLACE FUNCTION tgv_functions.models_create (proj_name character varying, mod_name character varying, orig boolean DEFAULT true, parm_name character varying DEFAULT 'default') RETURNS void AS $$ 
    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN  
            IF NOT tgv_functions.models_exists(proj_name,mod_name) THEN
                IF tgv_functions.parameter_groups_exists(parm_name) THEN
                    INSERT INTO tgv_data.tgv_models (project_id, model_id, parameter_id, original) VALUES (proj_name, mod_name, parm_name, orig);
                ELSE
                    RAISE EXCEPTION 'Non existing parameter id: %', parm_name USING HINT = 'Use another id for parameter record';
                END IF;       
            ELSE
                RAISE EXCEPTION 'Duplicate model id: %', mod_name USING HINT = 'Choose another id for new model';
            END IF;       
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Choose another id for project';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tgv_functions.models_read (proj_name character varying, mod_name character varying) RETURNS character varying AS $$ 
    DECLARE
        result jsonb := '{}'::jsonb;
    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN  
            IF tgv_functions.models_exists(proj_name,mod_name) THEN
                SELECT row_to_json(m) INTO result FROM tgv_data.tgv_models m  WHERE m.project_id = proj_name AND m.model_id = mod_name; 
            ELSE
                RAISE EXCEPTION 'Non existing model id: %', mod_name USING HINT = 'Choose another id for model';
            END IF;       
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Choose another id for project';
        END IF;
        RETURN (result::character varying);
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tgv_functions.models_update (proj_name character varying, mod_name character varying, orig boolean, parm_name character varying) RETURNS void AS $$ 
    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN  
            IF tgv_functions.models_exists(proj_name,mod_name) THEN
                IF COALESCE(parm_name,'') <> '' THEN 
                    IF tgv_functions.parameter_groups_exists(parm_name) THEN
                        UPDATE tgv_data.tgv_models SET parameter_id = parm_name WHERE model_id = mod_name; 
                    ELSE
                        RAISE EXCEPTION 'Non existing parameter id: %', parm_name USING HINT = 'Use another id for parameter record';
                    END IF;
                END IF;       
                IF orig IS NOT NULL THEN
                    UPDATE tgv_data.tgv_models SET original = orig WHERE model_id = mod_name; 
                END IF;
            ELSE
                RAISE EXCEPTION 'Non existing model id: %', mod_name USING HINT = 'Choose another id for model';
            END IF;       
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Choose another id for project';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tgv_functions.models_delete(proj_name character varying, mod_name character varying) RETURNS void AS $$
    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN 
            IF tgv_functions.models_exists(proj_name,mod_name) THEN
                DELETE FROM tgv_data.tgv_models WHERE project_id = proj_name AND model_id = mod_name;
            ELSE
                RAISE EXCEPTION 'Non existing model id: %', mod_name USING HINT = 'Use another id for model to delete';
            END IF;
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Use another id for project to delete model';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tgv_functions.models_copy (proj_name character varying, mod_name character varying, new_name character varying, deep_copy boolean DEFAULT false) RETURNS void AS $$
    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN 
            IF tgv_functions.models_exists (proj_name,mod_name) THEN 
                IF NOT tgv_functions.models_exists (new_name) THEN 
                    INSERT INTO tgv_data.tgv_models 
                        SELECT project_id, new_name AS model_id, parameter_id, original FROM tgv_data.tgv_models WHERE project_id = proj_name AND model_id = mod_name;
                    IF deep_copy THEN
                        INSERT INTO tgv_data.tgv_cell_values SELECT project_id,new_name AS model_id,cell_no,date_stamp, NULL AS pdate_stamp, depth FROM tgv_data.cell_values WHERE project_id = proj_name AND model_id = mod_name;
                        INSERT INTO tgv_data.tgv_cell_calculations 
                            SELECT project_id,new_name AS model_id,cell_no,year,depths,days_tot,days_mut1,days_mut2 FROM tgv_data.tgv_cell_calculations WHERE project_id = proj_name AND model_id = mod_name;
                        INSERT INTO tgv_data.tgv_building_costs 
                            SELECT project_id,building_id,new_name AS model_id,cell_no,year,cost FROM tgv_data.tgv_building_costs WHERE project_id = proj_name AND model_id = mod_name;
                     END IF;
                ELSE
                    RAISE EXCEPTION 'Existing model_id: %', new_name USING HINT = 'Choose another id for new model';
                END IF;
            ELSE
                RAISE EXCEPTION 'Non existing model id: %', mod_name USING HINT = 'Choose another id for model to copy';
            END IF;
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Choose another id for project to copy model from';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION tgv_functions.models_interpolate_cell_values(proj_name character varying, mod_name character varying) RETURNS void AS $$

    DECLARE 
        parm_json jsonb := NULL; 		 
        mpstr integer := NULL; 		 
        mpend integer := NULL; 		 
        ipstr integer := NULL;
        ipend integer := NULL;
        mplng integer := NULL;
        mpant integer := NULL;
        ipdis integer := NULL;

    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN 
            IF tgv_functions.models_exists (proj_name,mod_name) THEN 

                -- Find måleperiode start og slut samt interpolationsperiode start - slut ud fra brugerskabte parametre.
                SELECT p.parameter_values INTO parm_json FROM tgv_data.tgv_parameter_groups p JOIN tgv_data.tgv_models m ON p.parameter_id = m.parameter_id WHERE m.project_id = proj_name AND m.model_id = mod_name; 
                ipstr = (parm_json ->> 'year_start')::integer;
                ipend = (parm_json ->> 'year_end')::integer;
                mpstr = (parm_json ->> 'year_start_measure')::integer;
                mpend = (parm_json ->> 'year_end_measure')::integer;

                -- Beregn måleperiodens størrelse (begge år inkluderes)
                mplng = mpend - mpstr + 1;

                -- Loop over de enkelte år i interpolationsperiode
                FOR i IN ipstr..ipend LOOP

                    ipdis = i - mpend - 1;        -- Tidmæssig afstand mellem nuv. år og måleperiodens afslutning
                    mpant = DIV(ipdis,mplng) + 1; -- Find antallet af "hele" måleåerioder i "afstanden"
                    WITH c1 AS ( 
                        SELECT
                            tc.cell_no,
                            c.spring,
                            c.summer,
                            c.autumn,
                            c.winter,             -- Felterne spring, summer, autumn og winter indeholder cellens dybde korrektionsværdier for de enkelte årstider. Er beregnet i et tidlige funktion. 
                            mpant*mplng AS years, -- Antallet af år mellem interpolationsår og det oprindelige måleår
				        	generate_series((i::text||'-01-01')::date, (i::text||'-12-31')::date,'1 day'::interval)::date AS date_stamp -- Genererer datapunkter (celler/dato) indenfor interpolationsår
                        FROM tgv_data.tgv_cells tc JOIN tgv_data.tgv_cells c ON c.cell_no = tc.cell_no AND c.project_id = tc.project_id 
                        WHERE tc.project_id = proj_name),
		        	c2 AS ( 
			            SELECT 
        	                c1.cell_no,
                            c1.date_stamp,
                            (CASE EXTRACT(MONTH FROM c1.date_stamp) 
				                WHEN 3 THEN c1.spring WHEN 4 THEN c1.spring WHEN 5 THEN c1.spring 
        					    WHEN 6 THEN c1.summer WHEN 7 THEN c1.summer WHEN 8 THEN c1.summer 
		        			    WHEN 9 THEN c1.autumn WHEN 10 THEN c1.autumn WHEN 11 THEN c1.autumn 
				        	    ELSE c1.winter 
                            END)::real*c1.years AS dcorr, -- Korrektionsværdi for interpolationsår / måleår / celle
		        			(c1.date_stamp - (c1.years::text || ' YEARS')::interval)::date AS pdate_stamp -- Måleår, hvorfra den opr. dybde skal findes
			            FROM c1)
						
                    INSERT INTO tgv_data.tgv_cell_values 
                        SELECT 
                            proj_name AS project_id,
                            mod_name AS model_id,
                            c2.cell_no,
                            c2.date_stamp,
                            c2.pdate_stamp,
                            (cv.depth + c2.dcorr)::real AS depth 
                        FROM c2 JOIN tgv_data.tgv_cell_values cv ON
                            cv.project_id = proj_name AND cv.model_id = mod_name AND cv.cell_no = c2.cell_no AND cv.date_stamp = c2.pdate_stamp
					    ON CONFLICT ON CONSTRAINT tgv_cell_values_pkey DO UPDATE SET depth = EXCLUDED.depth, pdate_stamp = EXCLUDED.pdate_stamp;

                END LOOP; 
            ELSE
                RAISE EXCEPTION 'Non existing model id: %', mod_name USING HINT = 'Choose another id for model to copy';
            END IF; 
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Choose another id for project to copy model from';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;
--SELECT tgv_functions.models_interpolate_cell_values('Markby','Initial data');





CREATE OR REPLACE FUNCTION tgv_functions.models_create_cell_calculations(proj_name character varying, mod_name character varying) RETURNS void AS $$
    DECLARE 
        parm_json jsonb := NULL; 		 
        ydp integer;
        mut1 double precision;
        mut2 double precision;
        year_start integer;
        year_end integer;
    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN 
            IF tgv_functions.models_exists (proj_name,mod_name) THEN 

                SELECT p.parameter_values INTO parm_json FROM tgv_data.tgv_parameter_groups p JOIN tgv_data.tgv_models m ON p.parameter_id = m.parameter_id WHERE m.project_id = proj_name AND m.model_id = mod_name; 
                year_start = (parm_json ->> 'year_start')::integer;
                year_end = (parm_json ->> 'year_end')::integer;
                ydp = (parm_json ->> 'ydp')::integer;
                mut1 = (parm_json ->> 'mut1')::real;
                mut2 = (parm_json ->> 'mut2')::real;
                year_start = (parm_json ->> 'year_start')::integer;
                year_end = (parm_json ->> 'year_end')::integer;

                INSERT INTO tgv_data.tgv_cell_calculations (project_id, model_id, cell_no, year, depths,  days_tot, days_mut1, days_mut2) 
                SELECT 
                    project_id,
    			    model_id,
                    cell_no,
                    EXTRACT(YEAR FROM date_stamp - (ydp::text||' DAYS')::interval) AS year, -- Is it necessary with the diplacement days ?
                    NULL::real[] AS depths,
                    COUNT(*) AS days_tot,
                    COUNT (*) FILTER (WHERE depth <= mut1) AS days_mut1,				
                    COUNT (*) FILTER (WHERE depth <= mut2 /* AND depth > dmut1*/ ) AS days_mut2		
    		    FROM tgv_data.tgv_cell_values WHERE project_id = proj_name AND model_id = mod_name AND EXTRACT(YEAR FROM date_stamp) >= year_start AND EXTRACT(YEAR FROM date_stamp) < year_end -- Correct filter for years ?
                GROUP BY 1,2,3,4
                ON CONFLICT ON CONSTRAINT tgv_cell_calculations_pkey DO UPDATE SET depths = EXCLUDED.depths, days_tot = EXCLUDED.days_tot, days_mut1 = EXCLUDED.days_mut1, days_mut2 = EXCLUDED.days_mut2;                
            ELSE
                RAISE EXCEPTION 'Non existing model id: %', mod_name USING HINT = 'Choose another id for model to copy';
            END IF;
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Choose another id for project to copy model from';
        END IF;

        RETURN;
    END;
$$ LANGUAGE plpgsql;
--SELECT tgv_functions.models_create_cell_calculations('Markby','Initial data');


CREATE OR REPLACE FUNCTION tgv_functions.building_costs_calculate(proj_name character varying, mod_name character varying) RETURNS void AS $$
    DECLARE 
        proj_id uuid := NULL;
        mod_id uuid := NULL;
        parm_json jsonb := NULL; 		 
        ydp integer := 180;
        mut1 double precision :=1.0;
        mut2 double precision := 2.0;
        year_start integer := 2025;
        year_end integer := 2125;
        s1 double precision := 652.00;
        s2 double precision := 84.00;
        s3 double precision := 84.00;
		v0 integer := 0;
		v7 integer := 7;
		v30 integer := 30;
		v180 integer := 180;
		 
    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN 
            IF tgv_functions.models_exists (proj_name,mod_name) THEN 

                SELECT p.parameter_values INTO parm_json FROM tgv_data.tgv_parameter_groups p JOIN tgv_data.tgv_models m ON p.parameter_id = m.parameter_id WHERE m.project_id = proj_name AND m.model_id = mod_name; 
                ydp = (parm_json ->> 'ydp')::integer;
                mut1 = (parm_json ->> 'mut1')::double precision;
                mut2 = (parm_json ->> 'mut2')::double precision;
                year_start = (parm_json ->> 'year_start')::integer;
                year_end = (parm_json ->> 'year_end')::integer;
                s1 = (parm_json ->> 's1')::double precision;
                s2 = (parm_json ->> 's2')::double precision;
                s3 = (parm_json ->> 's3')::double precision;
                v0 = (parm_json ->> 'v0')::integer;
                v7 = (parm_json ->> 'v7')::integer;
                v30 = (parm_json ->> 'v30')::integer;
                v180 = (parm_json ->> 'v180')::integer;
        
                -- delete existing building costs for the model
                DELETE FROM tgv_data.tgv_building_costs WHERE project_id = proj_name AND model_id = mod_name;
                 
                -- run INSERT query
                WITH bc1 AS (
                    SELECT 
        			    b.building_id,
        			    b.cellar_area_m2,
                        b.cellar_perimeter_m,
                        st_area(bb.geom) as building_area_m2,
                        st_perimeter(bb.geom) as building_perimeter_m,
                        cc.project_id,
                        cc.model_id,
                        cc.cell_no,
                        cc.year,
                        cc.days_mut1,
                        cc.days_mut2,
                        -- local column bclass: 1->cellar & no protection; 2->cellar & protected 3->no cellar & no protection; 4->no cellar & protected  
                        (CASE WHEN b.cellar_area_m2 > 0.0 THEN 
                            CASE WHEN b.is_protected THEN 2 ELSE 1 END 
                        ELSE
                            CASE WHEN b.is_protected THEN 4 ELSE 3 END
                        END)::integer AS bclass 
                    FROM tgv_data.tgv_buildings b 
                        JOIN tgv_data.tgv_cell_calculations cc ON ST_Contains(cc.geom, ST_Centroid(b.geom))
                    WHERE cc.project_id = proj_name AND cc.model_id = mod_id
                )
                INSERT INTO tgv_data.tgv_building_costs 
                     SELECT 
        			    project_id,
        			    building_id,
        				model_id,
                        cell_no,
                        year,
                        (
                            -- local column bclass: 1->cellar & no protection; 2->cellar & protected 3->no cellar & no protection; 4->no cellar & protected  
                            CASE WHEN days_mut1 > v0   AND bclass = 1          THEN s1*building_area      ELSE 0.00 END + -- H1
                            CASE WHEN days_mut1 > v7   AND bclass = 2          THEN s1*building_area      ELSE 0.00 END + -- H2
                            CASE WHEN days_mut2 > v7   AND bclass = 1          THEN s2*cellar_perimeter   ELSE 0.00 END + -- V1
                            CASE WHEN days_mut1 > v7   AND bclass = 1          THEN s2*cellar_perimeter   ELSE 0.00 END + -- V2
                            CASE WHEN days_mut2 > v30  AND bclass = 1          THEN s2*cellar_perimeter   ELSE 0.00 END + -- V3
                            CASE WHEN days_mut1 > v30  AND bclass IN (1,3)     THEN s3*building_perimeter ELSE 0.00 END + -- V4
                            CASE WHEN days_mut1 > v30  AND bclass = 2          THEN s2*cellar_perimeter   ELSE 0.00 END + -- V4
                            CASE WHEN days_mut2 > v180 AND bclass IN (1,2)     THEN s2*cellar_perimeter   ELSE 0.00 END + -- V5
                            CASE WHEN days_mut1 > v180 AND bclass IN (1,2,3,4) THEN s3*building_perimeter ELSE 0.00 END   -- V6
                        )::NUMERIC(12,2) AS cost
                    FROM bc1
            ELSE
                RAISE EXCEPTION 'Non existing model id: %', mod_name USING HINT = 'Choose another id for model to copy';
            END IF;
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Choose another id for project to copy model from';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tgv_functions.cells_create_from_import(proj_name character varying, parm_name character varying) RETURNS void AS $$
    DECLARE 
        parm_json jsonb := NULL; 		 
        cell_size numeric := NULL;
        epsg_code integer := NULL;
		x_name character varying := NULL;
		y_name character varying := NULL;
		tab_name character varying := NULL;
        insert_sql character varying := '
INSERT INTO tgv_data.tgv_cells 
SELECT
    %1$L::character varying AS project_id,
    %2$I::bigint*10000000+%3$I::bigint AS cell_no,
    st_multi(st_makeenvelope(%2$I-%5$L, %3$I-%5$L,%2$I+%5$L,%3$I+%5$L,%4$s))::geometry(multipolygon,%4$s) AS geom
FROM (SELECT %2$I,%3$I FROM tgv_import.%6$I group by 1,2)
ON CONFLICT DO NOTHING;
';
    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN 
            IF tgv_functions.parameter_groups_exists (parm_name) THEN 
                SELECT p.parameter_values INTO parm_json FROM tgv_data.tgv_parameter_groups WHERE p.parameter_id = parm_name; 
                tab_name =  (parm_json ->> 'tab_name')::character varying;
                x_name =  (parm_json ->> 'x_name')::character varying;
                y_name =  (parm_json ->> 'y_name')::character varying;
                cell_size = (parm_json ->> 'cell_size')::numeric;
                epsg_code = (parm_json ->> 'epsg_code')::integer;
            EXECUTE FORMAT(insert_sql, proj_name, x_name, y_name, epsg_code, tab_name);
            ELSE
                RAISE EXCEPTION 'Non existing parameter id: %', parm_name USING HINT = 'Choose another id for parameter';
			END IF;
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Choose another id for project';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tgv_functions.cells_create_from_project_parameter(proj_name character varying, parm_name character varying) RETURNS void AS $$
    DECLARE 
        parm_json jsonb := NULL; 		 
        cell_size numeric := NULL;
        epsg_code integer := NULL;
		geome geometry := NULL;
        xmin double precision := NULL;
        xmax double precision := NULL;
        ymin double precision := NULL;
        ymax double precision := NULL;
        
    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN 
            IF tgv_functions.parameter_groups_exists (parm_name) THEN 

                SELECT parameter_values INTO parm_json FROM tgv_data.tgv_parameter_groups WHERE parameter_id = parm_name; 
                cell_size = (parm_json ->> 'cell_size')::numeric;
                epsg_code = (parm_json ->> 'epsg_code')::integer;

                SELECT geom INTO geome FROM tgv_data.tgv_projects WHERE project_id = proj_name; 
                xmin = (DIV(ST_XMin(geome)::numeric,cell_size)*cell_size)::double precision;
                xmax = (DIV(ST_XMax(geome)::numeric,cell_size)*cell_size+cell_size)::double precision;
                ymin = (DIV(ST_YMin(geome)::numeric,cell_size)*cell_size)::double precision;
                ymax = (DIV(ST_YMax(geome)::numeric,cell_size)*cell_size+cell_size)::double precision;

                WITH g AS (
                    SELECT (st_squaregrid(cell_size,ST_MakeEnvelope(xmin,ymin,xmax,ymax,epsg_code))).*
                ),
                g2 AS (
                    SELECT g.geom FROM g JOIN tgv_data.tgv_projects p ON ST_Intersects(g.geom, p.geom) AND p.project_id = proj_name
                )
                INSERT INTO tgv_data.tgv_cells (project_id, cell_no, geom)  
                SELECT 
                    proj_name AS project_id,
                    ST_X(ST_Centroid(g2.geom))::bigint*10000000+ST_Y(ST_Centroid(g2.geom))::bigint AS cell_no,
                    g2.geom AS geom FROM g2;
            ELSE
                RAISE EXCEPTION 'Non existing parameter id: %', parm_name USING HINT = 'Choose another id for parameter';
			END IF;
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Choose another id for project';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tgv_functions.cells_prune_from_project(proj_name character varying) RETURNS void AS $$
    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN 
            WITH pt AS (SELECT geom FROM tgv_data.tgv_projects WHERE project_id = proj_name) 
                DELETE FROM tgv_data.tgv_cells c USING pt WHERE c.project_id = proj_name AND ST_Disjoint(c.geom, pt.geom);
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Choose another id for project';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tgv_functions.cells_update_from_corrections(proj_name character varying, number_of_years real, seasonx character varying = '') RETURNS void AS $$

    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN 
            seasonx = COALESCE (LOWER(seasonx),'');
            WITH x AS (
                SELECT 
                    c.project_id,
                    c.cell_no,
                    c.geom,
                    (CASE WHEN seasonx IN ('spring','') THEN sp.depth/number_of_years ELSE NULL END)::real AS spring,
                    (CASE WHEN seasonx IN ('summer','') THEN su.depth/number_of_years ELSE NULL END)::real AS summer,
                    (CASE WHEN seasonx IN ('autumn','') THEN au.depth/number_of_years ELSE NULL END)::real AS autumn,
                    (CASE WHEN seasonx IN ('winter','') THEN wi.depth/number_of_years ELSE NULL END)::real AS winter
                FROM tgv_data.tgv_cells c
                LEFT JOIN tgv_data.tgv_corrections sp ON c.cell_no = sp.id AND c.project_id = sp.project_id AND sp.season = 'Spring'
                LEFT JOIN tgv_data.tgv_corrections su ON c.cell_no = su.id AND c.project_id = su.project_id AND su.season = 'Summer'
                LEFT JOIN tgv_data.tgv_corrections au ON c.cell_no = au.id AND c.project_id = au.project_id AND au.season = 'Autumn'
                LEFT JOIN tgv_data.tgv_corrections wi ON c.cell_no = wi.id AND c.project_id = wi.project_id AND wi.season = 'Winter'
            	WHERE c.project_id = proj_name)
            UPDATE tgv_data.tgv_cells t
                SET 
                    spring = COALESCE (x.spring, t.spring), 
                    summer = COALESCE (x.summer, t.summer), 
                    autumn = COALESCE (x.autumn, t.autumn), 
                    winter = COALESCE (x.winter, t.winter) 
                FROM x WHERE t.project_id = x.project_id AND t.cell_no = x.cell_no;
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Choose another id for project';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tgv_functions.cell_values_create_from_import(proj_name character varying, mod_name character varying) RETURNS void AS $$
    DECLARE 
        parm_name character varying := NULL;
        parm_json jsonb := NULL; 		 
		x_name character varying := NULL;
		y_name character varying := NULL;
		date_name character varying := NULL;
		depth_name character varying := NULL;
		tab_name character varying := NULL;
        insert_sql character varying := '
WITH r AS (
    SELECT
        %1$L::character varying AS project_id,
        %2$L::character varying AS model_id,
        %5$I::bigint*10000000+%6$I::bigint AS cell_no,
        %3$I::date AS date_stamp,
        NULL::date AS pdate_stamp,
        %4$I::real AS depth 
FROM tgv_import.%7$I
)
INSERT INTO tgv_data.tgv_cell_values 
    SELECT r.* FROM r JOIN tgv_data.tgv_cells c ON c.cell_no = r.cell_no AND c.project_id = %1$L::character varying
';
    BEGIN
        IF tgv_functions.projects_exists(proj_name) THEN 
            IF tgv_functions.models_exists (proj_name,mod_name) THEN 
                SELECT parameter_id INTO parm_name FROM tgv_data.tgv_models WHERE project_id = proj_name AND model_id = mod_name; 
                IF tgv_functions.parameter_groups_exists (parm_name) THEN 
                    SELECT parameter_values INTO parm_json FROM tgv_data.tgv_parameter_groups WHERE parameter_id = parm_name; 
                    tab_name = (parm_json ->> 'import_table')::character varying;
                    x_name = (parm_json ->> 'import_x')::character varying;
                    y_name = (parm_json ->> 'import_y')::character varying;
                    date_name = (parm_json ->> 'import_date')::character varying;
                    depth_name = (parm_json ->> 'import_depth')::character varying;
                    EXECUTE FORMAT(insert_sql, proj_name, mod_name, date_name, depth_name, x_name, y_name, tab_name);
                ELSE
                    RAISE EXCEPTION 'Non existing parameter id: %', parm_name USING HINT = 'Choose another id for parameter';
			    END IF;
            ELSE
                RAISE EXCEPTION 'Non existing model id: %', mod_name USING HINT = 'Choose another id for model';
			END IF;
        ELSE
            RAISE EXCEPTION 'Non existing project id: %', proj_name USING HINT = 'Choose another id for project';
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql;
