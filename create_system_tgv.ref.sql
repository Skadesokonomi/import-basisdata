-- Script to setup TGV schemas, tables and functions.

-- Setup PostGIS

CREATE EXTENSION IF NOT EXISTS postgis;

-- Schemas

DROP SCHEMA IF EXISTS fdc_tgv_data CASCADE;
DROP SCHEMA IF EXISTS fdc_tgv_import CASCADE;
DROP SCHEMA IF EXISTS fdc_tgv_functions CASCADE;

CREATE SCHEMA IF NOT EXISTS fdc_tgv_data; -- schema for data to TGV models
CREATE SCHEMA IF NOT EXISTS fdc_tgv_import; -- TGV import data
CREATE SCHEMA IF NOT EXISTS fdc_tgv_functions; -- TGV functions

-- Schema fdc_tgv_data tables 

SET search_path = fdc_tgv_data, public;

CREATE TABLE IF NOT EXISTS tgv_projects (
    project_id uuid DEFAULT gen_random_uuid(),
    project_name character varying NOT NULL UNIQUE,
    project_parms jsonb,
    geom Geometry(Multipolygon,25832)
);
ALTER TABLE tgv_projects ADD PRIMARY KEY (project_id);


CREATE TABLE IF NOT EXISTS tgv_models (
    model_id uuid DEFAULT gen_random_uuid(),
    model_name character varying NOT NULL UNIQUE,
    project_id uuid NOT NULL,
    original boolean NOT NULL DEFAULT FALSE,
    model_parms jsonb
);
ALTER TABLE tgv_models ADD PRIMARY KEY (model_id);
ALTER TABLE tgv_models ADD CONSTRAINT fk_tgv_models_projects 
    FOREIGN KEY (project_id) REFERENCES tgv_projects (project_id);


CREATE TABLE IF NOT EXISTS tgv_cells (
    cell_no bigint NOT NULL;
    project_id uuid NOT NULL,
    geom Geometry(Multipolygon,25832)
);
ALTER TABLE tgv_cells ADD PRIMARY KEY (cell_no);
ALTER TABLE tgv_cells ADD CONSTRAINT fk_tgv_cells_projects 
    FOREIGN KEY (project_id) REFERENCES tgv_projects (project_id);

CREATE TABLE IF NOT EXISTS tgv_cell_values (
    model_id uuid NOT NULL,
    cell_no bigint NOT NULL,
    date_value date NOT NULL,
    depth real 
);
ALTER TABLE tgv_cell_values ADD PRIMARY KEY (model_id,cell_no,date_value);
ALTER TABLE tgv_cell_values ADD CONSTRAINT fk_tgv_cell_values_models 
    FOREIGN KEY (model_id) REFERENCES tgv_models (model_id);
ALTER TABLE tgv_cell_values ADD CONSTRAINT fk_tgv_cell_values_cells 
    FOREIGN KEY (cell_no) REFERENCES tgv_cells (cell_no);


CREATE TABLE IF NOT EXISTS tgv_cell_calculations (
    model_id uuid NOT NULL,
    cell_no bigint NOT NULL,
    year integer NOT NULL CHECK (year >= 1900 AND year <= 2300),
    depths real[],
    days_mut1 integer,
    days_mut2 integer	
);
ALTER TABLE tgv_cell_calculations ADD PRIMARY KEY (model_id,cell_no,year);
ALTER TABLE tgv_cell_calculations ADD CONSTRAINT fk_tgv_cell_calculations_models 
    FOREIGN KEY (model_id) REFERENCES tgv_models (model_id);
ALTER TABLE tgv_cell_calculations ADD CONSTRAINT fk_tgv_cell_calculations_cells 
    FOREIGN KEY (cell_no) REFERENCES tgv_cells (cell_no);


CREATE TABLE IF NOT EXISTS tgv_buildings(
    building_id uuid DEFAULT gen_random_uuid(),
    build_usage_code integer,
    build_usage_text character varying,
	has_cellar boolean,
	is_protected boolean, 
	municipality_code integer,
    geom Geometry(Multipolygon,25832)
);
ALTER TABLE tgv_buildings ADD PRIMARY KEY (building_id);


CREATE TABLE IF NOT EXISTS tgv_building_costs (
    building_id uuid NOT NULL,
    model_id uuid NOT NULL,
    cell_no bigint NOT NULL,
    year integer NOT NULL CHECK (year >= 1900 AND year <= 2300),
    cost numeric(12,2) NOT NULL DEFAULT 0.0 CHECK (cost >= 0.0)   
);
ALTER TABLE tgv_building_costs ADD PRIMARY KEY (building_id,model_id,cell_no,year);
ALTER TABLE tgv_building_costs ADD CONSTRAINT fk_tgv_building_costs_buildings 
    FOREIGN KEY (building_id) REFERENCES tgv_buildings (building_id);
ALTER TABLE tgv_building_costs ADD CONSTRAINT fk_tgv_building_costs_models 
    FOREIGN KEY (model_id) REFERENCES tgv_models (model_id);
ALTER TABLE tgv_building_costs ADD CONSTRAINT fk_tgv_building_costs_cell_calculations 
    FOREIGN KEY (model_id,cell_no, year) REFERENCES tgv_cell_calculations (model_id,cell_no, year);

CREATE TABLE IF NOT EXISTS tgv_parameters (
    parameter_name character varying NOT NULL,
    parameter_values jsonb
);
ALTER TABLE tgv_parameters ADD PRIMARY KEY (parameter_name);

INSERT INTO tgv_parameters (parameter_name, parameter_values) VALUES (
'default',
'{
"YDP":180,
"MUT1": 1.0,
"MUT2": 2.0,
"S1": 652.00,
"S2": 84.00,
"S3": 84.00,
"YEAR_START": 2025,
"YEAR_END": 2125,
"V0": 0,
"V7": 7,
"V30": 30,
"V180": 180,
"WINTER_MEAN":0.1,
"SUMMER_MEAN":0.1,
"SPRING_MEAN":0.1,
"AUTUMN_MEAN":0.1,
"YEAR_START": 1990,
"YEAR_END": 2025,

}'
);

-- Schema fdc_tgv_functions functions

SET search_path = fdc_tgv_functions, public;

CREATE OR REPLACE FUNCTION create_parameters(new_name character varying, new_parameters character varying) 
    RETURNS record AS $$

    DECLARE 
         parm_json jsonb := NULL;
    BEGIN
        -- Check for parameter block existence
        IF (EXISTS(SELECT 1 FROM fdc_tgv_data.tgv_parameters WHERE parameter_name = new_name)) THEN  
            RETURN ('Error','Parameter block already exists', new_name, new_parameters);
        END IF;               
        INSERT INTO fdc_tgv_data.tgv_parameters (parameter_name, parameter_value) VALUES (new_name, new_parameters::jsonb);
        RETURN ('Succes','New parameter_block created', new_name, new_parameters);
    END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_parameters(parm_name character varying, new_parameters character varying) 
    RETURNS record AS $$

    DECLARE 
         parm_json jsonb := NULL;
    BEGIN
        -- Check for parameter block existence
        IF (NOT EXISTS(SELECT 1 FROM fdc_tgv_data.tgv_parameters WHERE parameter_name = parm_name)) THEN  
            RETURN ('Error','Parameter block does not exists', parm_name, new_parameters);
        END IF;               
        UPDATE fdc_tgv_data.tgv_parameters SET parameter_value =  (parameter_value) || (new_parameters::jsonb);
        RETURN ('Succes','Parameter block updated', new_name, new_parameters);
    END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION clone_parameters(parm_name character varying, new_name character varying) 
    RETURNS record AS $$

    BEGIN
        -- Check for parameter block existence
        IF (NOT EXISTS(SELECT 1 FROM fdc_tgv_data.tgv_parameters WHERE parameter_name = parm_name)) THEN  
            RETURN ('Error','Parameter block does not exists', parm_name, new_new_name);
        END IF;               
        IF (EXISTS(SELECT 1 FROM fdc_tgv_data.tgv_parameters WHERE parameter_name = new_name)) THEN  
            RETURN ('Error','Parameter block already not exists', parm_name, new_name);
        END IF;               
        INSERT INTO fdc_tgv_data.tgv_parameters (parameter_name,parameter_values)   
		    SELECT new_name,parameter_values FROM fdc_tgv_data.tgv_parameters WHERE parameter_name = parm_name;
        RETURN ('Succes','Parameter block cloned', parm_name,new_name);
    END;

$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_project(new_name character varying, new_wkt character varying) 
    RETURNS record AS $$

    DECLARE 
		 new_srid integer := 25832;
         parm_json jsonb := NULL;
    BEGIN
        -- Check for project existence
        IF (EXISTS(SELECT 1 FROM fdc_tgv_data.tgv_projects WHERE project_name = new_name)) THEN  
            RETURN ('Error','Project already exists', new_name, new_wkt);
        END IF;               
        SELECT value INTO parm_json FROM fdc_tgv_data.tgv_parameters WHERE name = 'default'; 
        INSERT INTO fdc_tgv_data.tgv_projects (project_name, parameters, geom) VALUES (new_name, parm_json, ST_GeomFromText(new_wkt, new_srid));
        RETURN ('Succes','New project created', new_name, new_wkt);
    END;

$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION set_project_parameters(proj_name character varying, parm_name character varying) 
    RETURNS record AS $$

    DECLARE 
         parm_json jsonb := NULL;
		 proj_id uuid := NULL;
    BEGIN
        -- Check for project existence
        SELECT project_id into proj_id FROM fdc_tgv_data.tgv_projects WHERE project_name = proj_name;
        IF proj_id IS NULL THEN  
            RETURN ('Error','Project does not exist, parameters not updated', proj_name, parm_name);
        END IF;
        -- Check for parameter block existence
        SELECT value INTO parm_json FROM fdc_tgv_data.tgv_parameters WHERE name = parm_name; 
        IF parm_json IS NULL THEN  
            RETURN ('Error','Parameter block does not exist, parameters not updated', proj_name, parm_name);
        END IF;
        UPDATE fdc_tgv_data.tgv_projects SET project_parms = parm_json WHERE project_id = proj_id; 
        RETURN ('Succes','Project parameters for project updated.', proj_name, parm_name);
    END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_model(proj_name character varying, new_name character varying, orig boolean) 
    RETURNS record AS $$

    DECLARE 
         parm_json jsonb := NULL;
		 proj_id uuid := NULL;

    BEGIN
        -- Check for project existence
        SELECT project_id, project_parm into proj_id, parm_json FROM fdc_tgv_data.tgv_projects WHERE project_name = proj_name;
		IF proj_id IS NULL THEN
            RETURN ('Error','Project does not exist, new model not created', proj_name, new_name,orig);
        END IF;
        -- Check for model existence
        IF (NOT EXISTS(SELECT 1 FROM fdc_tgv_data.tgv_models WHERE model_name = new_name AND project_id = proj_id)) THEN  
            INSERT INTO fdc_tgv_data.tgv_models (project_id,model_name,model_parm,original) VALUES (proj_id,new_name,parm_json,orig);
                RETURN ('Succes','New project created in project', proj_name, new_name,orig);
            ELSE
                RETURN ('Error','Model already exists', proj_name, new_name,orig);
            END IF;
    END;

$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION set_model_parameters(proj_name character varying, mod_name character varying, parm_name character varying) 
    RETURNS record AS $$

    DECLARE 
         parm_json jsonb := NULL;
		 proj_id uuid := NULL;
		 mod_id uuid := NULL;
    BEGIN
        -- Check for project existence
        SELECT project_id into proj_id FROM fdc_tgv_data.tgv_projects WHERE project_name = proj_name;
        IF proj_id IS NULL THEN  
            RETURN ('Error','Project does not exist, parameters not updated', proj_name, parm_name);
        END IF;
        -- Check for model existence
        SELECT model_id into mod_id FROM fdc_tgv_data.tgv_models WHERE model_name = mod_name AND project_id = proj_id;
        IF mod_id IS NULL THEN  
            RETURN ('Error','Model for project does not exist, parameters not updated', proj_name, mod_name, parm_name);
        END IF;
        -- Check for parameter block existence
        SELECT value INTO parm_json FROM fdc_tgv_data.tgv_parameters WHERE name = parm_name; 
        IF parm_json IS NULL THEN  
            RETURN ('Error','Parameter block does not exist, parameters not updated', proj_name, mod_name, parm_name);
        END IF;
        UPDATE fdc_tgv_data.tgv_models SET model_parms = parm_json WHERE model_id = mod_id; 
        RETURN ('Succes','Project parameters for model updated.', proj_name, mod_name, parm_name);
    END;

$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION import_model_data(proj_name character varying, mod_name character varying, file_name character varying) 
    RETURNS record AS $$

    DECLARE 
		 proj_id uuid := NULL;
		 mod_id uuid := NULL;
		 new_id uuid := NULL;
		 
    BEGIN
        -- Check for project existence
        SELECT project_id into proj_id FROM fdc_tgv_data.tgv_projects WHERE project_name = proj_name;
        IF proj_id IS NULL THEN  
            RETURN ('Error','Project does not exist, cannot start importing data', proj_name, mod_name, file_name);
        END IF;
        -- Check for model existence
        SELECT model_id into mod_id FROM fdc_tgv_data.tgv_models WHERE model_name = mod_name AND project_id = proj_id;
        IF mod_id IS NULL THEN  
            RETURN ('Error','Model for project does not exist, cannot start importing data', proj_name, mod_name, file_name);
        END IF;
        -- Import data...
        RETURN('Succes','Data imported into project/model', proj_name, mod_name_name,file_name);
    END;

$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION clone_model(proj_name character varying, mod_name character varying, new_name character varying) 
    RETURNS record AS $$

    DECLARE 
		 proj_id uuid := NULL;
		 mod_id uuid := NULL;
		 new_id uuid := NULL;
		 
    BEGIN
        -- Check for project existence
        SELECT project_id into proj_id FROM fdc_tgv_data.tgv_projects WHERE project_name = proj_name;
        IF proj_id IS NULL THEN  
            RETURN ('Error','Project does not exist, cannot start cloning', proj_name, mod_name, new_name);
        END IF;
        -- Check for model existence
        SELECT model_id into mod_id FROM fdc_tgv_data.tgv_models WHERE model_name = mod_name AND project_id = proj_id;
        IF mod_id IS NULL THEN  
            RETURN ('Error','Model for project does not exist, cannot start cloning', proj_name, mod_name, new_name);
        END IF;
        -- Check for model (non) existence
        IF (EXISTS(SELECT 1 FROM fdc_tgv_data.tgv_models WHERE model_name = new_name)) THEN  
            RETURN ('Error','Model already exists', proj_name, mod_name, new_name);
        END IF;
        INSERT INTO fdc_tgv_data.tgv_models (model_name,project_id,original,model_parms) 
		    SELECT (model_name||' new',proj_id,false,model_parms) FROM fdc_tgv_data.tgv_models WHERE model_id = mod_id 
			    RETURNING model_id INTO new_id;
        INSERT INTO fdc_tgv_data.tgv_cell_values (model_id,cell_no,date_value,depth)   
		    SELECT new_id,cell_no,date_value,depth FROM fdc_tgv_data.tgv_cell_values WHERE model_id = mod_id;
        RETURN ('Succes','Model and cell values cloned', proj_name, mod_name_name,new_name);
    END;

$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION extrapolate_model_data(proj_name character varying, mod_name character varying)
    RETURNS record AS $$

    DECLARE 
        proj_id uuid := NULL;
        mod_id uuid := NULL;
        parm_json jsonb := NULL; 		 
        ydp integer;
        mut1 double precision;
        mut2 double precision;
        year_start integer;
        year_end integer;
		 
    BEGIN
        -- Check for project existence
        SELECT project_id into proj_id FROM fdc_tgv_data.tgv_projects WHERE project_name = proj_name;
        IF proj_id IS NULL THEN  
            RETURN ('Error','Project does not exist, cannot extrapolate data', proj_name, mod_name);
        END IF;
        -- Check for model existence
        SELECT model_id, model_parms  into mod_id, parm_json FROM fdc_tgv_data.tgv_models WHERE model_name = mod_name AND project_id = proj_id;
        IF mod_id IS NULL THEN  
            RETURN ('Error','Model for project does not exist, cannot extrapolate data', proj_name, mod_name);
        END IF;

        year_start = (parm_json ->> 'YEAR_START')::integer;
        year_end = (parm_json ->> 'YEAR_END')::integer;
        
        -- Extrapolate data
        INSERT INTO fdc_tgv_data.tgv_cell_values SELECT * FROM
        WITH days as (
            SELECT 
                mod_id AS model_id,
                generate_series(TO_DATE(year_start::text||'0101','YYYYMMDD')::date,TO_DATE(year_end::text||'1231','YYYYMMDD')::date, '1 day'::interval)::date as date_value
        ),
        cell_dates as (
            SELECT 
                d.model_id,
                tc.cell_no,
                d.date_value,
                0.0 as depth
            FROM days d JOIN fdc_tgv_data.tgv_cells tc
            WHERE tc.project_id = proj_id
        )
        SELECT
            cd.model_id,
            cd.cell_no,
            cd.data_value,
            0.0 AS depth -- calculation is missing 
        FROM cell_dates cd 
        LEFT JOIN fdc_tgv_data.tgv_cell_values cv ON cv.cell_no = cd.cell_no         
        WHERE cv.cell_no IS NULL -- all cell/date that's missing


        RETURN ('Succes','Data extrapolated for project/model', proj_name, mod_name);
    END;

$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calculate_model_year_values(proj_name character varying, mod_name character varying, parm_name character varying) RETURNS record AS $$

    DECLARE 
        proj_id uuid := NULL;
        mod_id uuid := NULL;
        parm_json jsonb := NULL; 		 
        ydp integer;
        mut1 double precision;
        mut2 double precision;
        year_start integer;
        year_end integer;

    BEGIN
        -- Check for project existence
        SELECT project_id into proj_id FROM fdc_tgv_data.tgv_projects WHERE project_name = proj_name;
        IF proj_id IS NULL THEN  
            RETURN ('Error','Project does not exist, cannot calculate year-data', proj_name, mod_name);
        END IF;
        -- Check for model existence
        SELECT model_id, model_parms  into mod_id, parm_json FROM fdc_tgv_data.tgv_models WHERE model_name = mod_name AND project_id = proj_id;
        IF mod_id IS NULL THEN  
            RETURN ('Error','Model for project does not exist, cannot calculate year-data', proj_name, mod_name);
        END IF;

        ydp = (parm_json ->> 'YDP')::integer;
        mut1 = (parm_json ->> 'MUT1')::real;
        mut2 = (parm_json ->> 'MUT2')::real;
        year_start = (parm_json ->> 'YEAR_START')::integer;
        year_end = (parm_json ->> 'YEAR_END')::integer;

		INSERT INTO fdc_tgv_data.tgv_cell_calculations (model_id, cell_no, year, mut1_days, mut2_days) 
            SELECT 
			    model_id,
                cell_no,
                year(date_value - ydp) AS year, -- Is it necessary with the diplacement days ?
                COUNT (*) FILTER (WHERE depth <= mut1) AS mut1_days,				
                COUNT (*) FILTER (WHERE depth <= mut2 AND depth > dmut1) AS mut2_days -- perhaps: depth <= dmut2  ?			
		    FROM fdc_tgv_data.tgv_cell_values WHERE model_id = mod_id AND year(data_value) >= year_start AND year(data_value) < year_end -- Correct filter for years ?
            GROUP BY 1,2,3;			
		RETURN ('Succes','Data calculated for project/model', proj_name, mod_name);
    END;

$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calculate_building_costs(proj_name character varying, mod_name character varying) RETURNS record AS $$

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
        -- Check for project existence
        SELECT project_id into proj_id FROM fdc_tgv_data.tgv_projects WHERE project_name = proj_name;
        IF proj_id IS NULL THEN  
            RETURN ('Error','Project does not exist, cannot calculate year-data', proj_name, mod_name);
        END IF;
        -- Check for model existence
        SELECT model_id, model_parms  into mod_id, parm_json FROM fdc_tgv_data.tgv_models WHERE model_name = mod_name AND project_id = proj_id;
        IF mod_id IS NULL THEN  
            RETURN ('Error','Model for project does not exist, cannot calculate year-data', proj_name, mod_name);
        END IF;

        -- set parameters from parameter block
        ydp = (parm_json ->> 'YDP')::integer;
        mut1 = (parm_json ->> 'MUT1')::double precision;
        mut2 = (parm_json ->> 'MUT2')::double precision;
        year_start = (parm_json ->> 'YEAR_START')::integer;
        year_end = (parm_json ->> 'YEAR_END')::integer;
        s1 = (parm_json ->> 'S1')::double precision;
        s2 = (parm_json ->> 'S2')::double precision;
        s3 = (parm_json ->> 'S3')::double precision;
        v0 = (parm_json ->> 'V0')::integer;
        v7 = (parm_json ->> 'V7')::integer;
        v30 = (parm_json ->> 'V30')::integer;
        v180 = (parm_json ->> 'V180')::integer;

        -- delete existing building costs for the model
        DELETE FROM fdc_tgv_data.building_costs WHERE model_id = mod_id;
         
        -- run INSERT query
        WITH bc1 AS (
            SELECT 
			    b.building_id,
                cc.model_id,
                cc.cell_no,
                cc.year,
                cc.days_mut1,
                cc.days_mut2,
                st_area(bb.geom) as building_area,
                st_perimeter(bb.geom) as building_perimeter,
                -- local column bclass: 1->cellar & no protection; 2->cellar & protected 3->no cellar & no protection; 4->no cellar & protected  
                (CASE WHEN b.has_cellar THEN 
                    CASE WHEN b.is_protected THEN 2 ELSE 1 END 
                ELSE
                    CASE WHEN b.is_protected THEN 4 ELSE 3 END
                END)::integer AS bclass 
            FROM fdc_tgv_data.tgv_buildings b 
                JOIN fdc_tgv_data.tgv_cell_calculations cc ON ST_Contains(cc.geom, ST_Centroid(b.geom))
            WHERE cc.model_id = mod_id
        ),
        bc2 AS (
            SELECT 
			    building_id,
				model_id,
                cell_no,
                year,
                (
                    -- local column bclass: 1->cellar & no protection; 2->cellar & protected 3->no cellar & no protection; 4->no cellar & protected  
                    CASE WHEN days_mut1 > v0   AND bclass = 1          THEN s1*building_area      ELSE 0.00 END + -- H1
                    CASE WHEN days_mut1 > v7   AND bclass = 2          THEN s1*building_area      ELSE 0.00 END + -- H2
                    CASE WHEN days_mut2 > v7   AND bclass = 1          THEN s2*building_perimeter ELSE 0.00 END + -- V1
                    CASE WHEN days_mut1 > v7   AND bclass = 1          THEN s2*building_perimeter ELSE 0.00 END + -- V2
                    CASE WHEN days_mut2 > v30  AND bclass = 1          THEN s2*building_perimeter ELSE 0.00 END + -- V3
                    CASE WHEN days_mut1 > v30  AND bclass IN (1,3)     THEN s3*building_perimeter ELSE 0.00 END + -- V4
                    CASE WHEN days_mut1 > v30  AND bclass = 2          THEN s2*building_perimeter ELSE 0.00 END + -- V4
                    CASE WHEN days_mut2 > v180 AND bclass IN (1,2)     THEN s2*building_perimeter ELSE 0.00 END + -- V5
                    CASE WHEN days_mut1 > v180 AND bclass IN (1,2,3,4) THEN s3*building_perimeter ELSE 0.00 END   -- V6
                )::NUMERIC(12,2) AS cost
        )
        INSERT INTO fdc_tgv_data.building_costs SELECT * FROM bc2;        
        RETURN ('Succes','Buiding costs calculated for project/model', proj_name, mod_name);
    END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_cells_from_import(
    proj_name character varying, mod_name character varying, tab_name character varying, 
    epsg_code integer, x_name character varying, y_name character varying) RETURNS record AS $$

    DECLARE 
        proj_id uuid := NULL;
        mod_id uuid := NULL;
        insert_sql character varying := '
INSERT INTO fdc_tgv_data.tgv_cells 
SELECT
    %2$I::bigint*10000000+%3$I::bigint AS cell_no
    %1$L::uuid AS project_id,
    st_multi(st_makeenvelope(%2$I-50.0, %3$I-50.0,%2$I+50.0,%3$I+50.0,%4$s))::geometry(multipolygon,%4$s) AS geom
FROM (SELECT %2$I,%3$I FROM fdc_tgv_import.%5$I group by 1,2)
ON CONFLICT DO NOTHING;
';
		 
    BEGIN
        -- Check for project existence
        SELECT project_id into proj_id FROM fdc_tgv_data.tgv_projects WHERE project_name = proj_name;
        IF proj_id IS NULL THEN  
            RETURN ('Error','Project does not exist, cannot calculate year-data', proj_name, mod_name);
        END IF;
        -- Check for model existence
        SELECT model_id into mod_id FROM fdc_tgv_data.tgv_models WHERE model_name = mod_name AND project_id = proj_id;
        IF mod_id IS NULL THEN  
            RETURN ('Error','Model for project does not exist, cannot calculate year-data', proj_name, mod_name);
        END IF;

        EXECUTE FORMAT(insert_sql, proj_id, x_name, y_name, epsg_code, tab_name);

        RETURN ('Succes','Insert of raw data into cells finished', proj_name, mod_name, tab_name);
    END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_cell_values_from_import(
    proj_name character varying, mod_name character varying, tab_name character varying, 
    x_name character varying, y_name character varying,
    date_name character varying, depth_name character varying) RETURNS record AS $$

    DECLARE 
        proj_id uuid := NULL;
        mod_id uuid := NULL;
        insert_sql character varying := '
INSERT INTO fdc_tgv_data.tgv_cell_values 
SELECT
    %1$L::uuid AS model_id,
    %2$I::bigint*10000000+%3$I::bigint AS cell_no
    %4$I::date AS date,
    %4$I::real AS depth
FROM (SELECT %2$I,%3$I,%4$I,%5$I FROM fdc_tgv_import.%6$I)
ON CONFLICT DO NOTHING;
';
		 
    BEGIN
        -- Check for project existence
        SELECT project_id into proj_id FROM fdc_tgv_data.tgv_projects WHERE project_name = proj_name;
        IF proj_id IS NULL THEN  
            RETURN ('Error','Project does not exist, cannot calculate year-data', proj_name, mod_name);
        END IF;
        -- Check for model existence
        SELECT model_id into mod_id FROM fdc_tgv_data.tgv_models WHERE model_name = mod_name AND project_id = proj_id;
        IF mod_id IS NULL THEN  
            RETURN ('Error','Model for project does not exist, cannot calculate year-data', proj_name, mod_name);
        END IF;

        EXECUTE FORMAT(insert_sql, mod_id, x_name, y_name, date_name, depth_name, tab_name);

        RETURN ('Succes','Insert of raw data into cell values finished', proj_name, mod_name, tab_name);
    END;

$$ LANGUAGE plpgsql;
