-- Script to setup TGV schemas, tables and functions.

-- Setup PostGIS

CREATE EXTENSION IF NOT EXISTS postgis;

-- Schemas

DROP SCHEMA IF EXISTS fdc_tgv_data CASCADE;
DROP SCHEMA IF EXISTS fdc_tgv_lookup CASCADE;
DROP SCHEMA IF EXISTS fdc_tgv_functions CASCADE;

CREATE SCHEMA IF NOT EXISTS fdc_tgv_data; -- schema for data to TGV models
CREATE SCHEMA IF NOT EXISTS fdc_tgv_lookup; -- TGV lookup data
CREATE SCHEMA IF NOT EXISTS fdc_tgv_functions; -- TGV functions

-- Schema fdc_tgv_data tables 

SET search_path = fdc_tgv_data, public;

CREATE TABLE IF NOT EXISTS tgv_projects (
    project_id uuid DEFAULT gen_random_uuid(),
    project_name character varying NOT NULL UNIQUE,
    parameter_1 double precision NOT NULL,
    parameter_2 double precision NOT NULL,
    geom Geometry(Multipolygon,25832)
);
ALTER TABLE tgv_projects ADD PRIMARY KEY (project_id);


CREATE TABLE IF NOT EXISTS tgv_models (
    model_id uuid DEFAULT gen_random_uuid(),
    model_name character varying NOT NULL UNIQUE,
    project_id uuid NOT NULL,
    original boolean NOT NULL DEFAULT FALSE,
    parameter_1 double precision NOT NULL,
    parameter_2 double precision NOT NULL
);
ALTER TABLE tgv_models ADD PRIMARY KEY (model_id);
ALTER TABLE tgv_models ADD CONSTRAINT fk_tgv_models_projects 
  FOREIGN KEY (project_id) REFERENCES tgv_projects (project_id);


CREATE TABLE IF NOT EXISTS tgv_cells (
    cell_id uuid DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    geom Geometry(Multipolygon,25832)
);
ALTER TABLE tgv_cells ADD PRIMARY KEY (cell_id);
ALTER TABLE tgv_cells ADD CONSTRAINT fk_tgv_cells_projects 
  FOREIGN KEY (project_id) REFERENCES tgv_projects (project_id);


CREATE TABLE IF NOT EXISTS tgv_cell_values (
    model_id uuid NOT NULL,
    cell_id uuid NOT NULL,
    date_value date NOT NULL,
    depth double precision 
);
ALTER TABLE tgv_cell_values ADD PRIMARY KEY (model_id,cell_id,date_value);
ALTER TABLE tgv_cell_values ADD CONSTRAINT fk_tgv_cell_values_models 
    FOREIGN KEY (model_id) REFERENCES tgv_models (model_id);
ALTER TABLE tgv_cell_values ADD CONSTRAINT fk_tgv_cell_values_cells 
    FOREIGN KEY (cell_id) REFERENCES tgv_cells (cell_id);


CREATE TABLE IF NOT EXISTS tgv_cell_calculations (
    model_id uuid NOT NULL,
    cell_id uuid NOT NULL,
    year integer NOT NULL CHECK (year >= 1900 AND year <= 2300),
    days integer  
);
ALTER TABLE tgv_cell_calculations ADD PRIMARY KEY (model_id,cell_id,year);
ALTER TABLE tgv_cell_calculations ADD CONSTRAINT fk_tgv_cell_calculations_models 
    FOREIGN KEY (model_id) REFERENCES tgv_models (model_id);
ALTER TABLE tgv_cell_calculations ADD CONSTRAINT fk_tgv_cell_calculations_cells 
    FOREIGN KEY (cell_id) REFERENCES tgv_cells (cell_id);


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
    cell_id uuid NOT NULL,
    year integer NOT NULL CHECK (year >= 1900 AND year <= 2300),
    cost numeric(12,2) NOT NULL DEFAULT 0.0 CHECK (cost >= 0.0)   
);
ALTER TABLE tgv_building_costs ADD PRIMARY KEY (building_id,model_id,cell_id,year);
ALTER TABLE tgv_building_costs ADD CONSTRAINT fk_tgv_building_costs_buildings 
    FOREIGN KEY (building_id) REFERENCES tgv_buildings (building_id);
ALTER TABLE tgv_building_costs ADD CONSTRAINT fk_tgv_building_costs_models 
    FOREIGN KEY (model_id) REFERENCES tgv_models (model_id);
ALTER TABLE tgv_building_costs ADD CONSTRAINT fk_tgv_building_costs_cell_calculations 
    FOREIGN KEY (model_id,cell_id, year) REFERENCES tgv_cell_calculations (model_id,cell_id, year);


-- Schema fdc_tgv_lookup tables 

SET search_path = fdc_tgv_lookup, public;

CREATE TABLE IF NOT EXISTS tgv_parameters (
    name character varying NOT NULL,
    num_value double precision NOT NULL,
    txt_value character_varying NOT NULL
);
ALTER TABLE tgv_parameters ADD PRIMARY KEY (name);

INSERT INTO tgv_parameters (name, value) VALUES(
    ('START',9,''),
    ('SDAY',180,''),
    ('MUT_1',1.0,''),
    ('MUT_2',2.0,''),
    ('S1',652.00),'',
    ('S2',84.00,''),
    ('S3',84.00,''),
    ('H1',84.00,''),
    ('H1',84.00,''),
    ('H2',84.00,''),
    ('V1',84.00,''),
    ('V2',84.00,''),
    ('V3',84.00,''),
    ('V4',84.00,''),
    ('V5',84.00,''),
    ('V6',84.00,''),
)

-- Schema fdc_tgv_functions functions

SET search_path = fdc_tgv_functions, public;

CREATE OR REPLACE FUNCTION create_project(new_name character varying, new_wkt character varying) RETURNS record AS $$

    DECLARE 
	     return_value record;
		 new_srid integer := 25832;

    BEGIN
        IF (NOT EXISTS(SELECT 1 FROM fdc_tgv_data.tgv_projects WHERE project_name = new_name)) THEN  
            INSERT INTO fdc_tgv_data.tgv_projects (project_name, parameter_1, parameter_2, geom) VALUES (new_name, 0.0, 0.0, ST_GeomFromText(new_wkt, new_srid));
            return_value = ('Succes','New project created', new_name, new_wkt);
        ELSE
            return_value = ('Error','Project already exists', new_name, new_wkt);
        END IF;               
        RETURN return_value;
    END;

$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION set_project_parameters(proj_name character varying, new_param_1 double precision, new_param_2 double precision) RETURNS record AS $$

    DECLARE 
	     return_value record;

    BEGIN
        IF (EXISTS(SELECT 1 FROM fdc_tgv_data.tgv_projects WHERE project_name = proj_name)) THEN  
            UPDATE fdc_tgv_data.tgv_projects SET parameter_1 = new_param_1, parameter_2 = new_param_2 WHERE project_name = proj_name; 
            return_value = ('Succes','Project parameters for project updated.', proj_name, new_param_1, new_param_2);
        ELSE
            return_value = ('Error','Project does not exist, parameters not updated', proj_name, new_param_1, new_param_2);
        END IF;               
        RETURN return_value;
    END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_model(proj_name character varying, new_name character varying, orig boolean) RETURNS record AS $$

    DECLARE 
	     return_value record;
		 proj_id uuid := NULL;

    BEGIN
        SELECT project_id into proj_id FROM fdc_tgv_data.tgv_projects WHERE project_name = proj_name;
		IF proj_id IS NOT NULL THEN
            IF (NOT EXISTS(SELECT 1 FROM fdc_tgv_data.tgv_models WHERE model_name = new_name)) THEN  
                INSERT INTO fdc_tgv_data.tgv_models (project_id,model_name,parameter_1, parameter_2,original) VALUES (proj_id,new_name,0.0,0.0,orig);
                return_value = ('Succes','New project created in project', proj_name, new_name,orig);
            ELSE
                return_value = ('Error','Model already exists', proj_name, new_name,orig);
            END IF;
        ELSE			
            return_value = ('Error','Project does not exist, new model not created', proj_name, new_name,orig);
        END IF;               
        RETURN return_value;
    END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION import_model_data(proj_name character varying, mod_name character varying, file_name character varying) RETURNS record AS $$

    DECLARE 
	     return_value record;
		 model_uuid uuid;
		 
    BEGIN
        model_uuid = NULL;
		SELECT a.model_id INTO model_uuid FROM fdc_tgv_data.tgv_models m JOIN fdc_tgv_data.tgv_projects p ON 
		    m.project_id = p.project_id AND m.model_name = mod_name AND p.project_name = proj_name;   
        IF model_uuid IS NOT NULL THEN
            -- Import data...
            return_value = ('Succes','Data imported into project/model', proj_name, mod_name_name,file_name);
		ELSE
            return_value = ('Error','Data *not* imported into project/model, project og model name does not exist', proj_name, mod_name_name,file_name);
        END IF;               
        RETURN return_value;
    END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_model_parameters(
    proj_name character varying, mod_name character varying, new_param_1 double precision, new_param_2 double precision) RETURNS record AS $$

    DECLARE 
	     return_value record;
		 model_uuid uuid;
		 
    BEGIN
        model_uuid = NULL;
		SELECT m.model_id INTO model_uuid FROM fdc_tgv_data.tgv_models m JOIN fdc_tgv_data.tgv_projects p ON 
		    m.project_id = p.project_id AND m.model_name = mod_name AND p.project_name = proj_name;   
        IF model_uuid IS NOT NULL THEN
            UPDATE fdc_tgv_data.tgv_models SET parameter_1 = new_param_1, parameter_2 = new_param_2 WHERE model_id = model_uuid; 
            return_value = ('Succes','Parameters for model updated.', proj_name, mod_name, new_param_1, new_param_2);
        ELSE
            return_value = ('Error','Project or model does not exist, parameters not updated', proj_name, mod_name, new_param_1, new_param_2);
        END IF;               
        RETURN return_value;
    END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION clone_model(
    proj_name character varying, mod_name character varying, new_name character varying) RETURNS record AS $$

    DECLARE 
	     return_value record;
		 model_uuid uuid;
		 
    BEGIN
        model_uuid = NULL;
		SELECT a.model_id INTO model_uuid FROM fdc_tgv_data.tgv_models m JOIN fdc_tgv_data.tgv_projects p ON 
		    m.project_id = p.project_id AND m.model_name = mod_name AND p.project_name = proj_name;   
        IF model_uuid IS NOT NULL THEN
            IF (NOT EXISTS(SELECT 1 FROM fdc_tgv_data.tgv_models WHERE model_name = new_name)) THEN  
                INSERT INTO fdc_tgv_data.tgv_models (project_name,model_name) VALUES (proj_name,new_name);
                return_value = ('Succes','New model cloned for project', proj_name, new_name);
            ELSE
                return_value = ('Error','Model already exists', proj_name, new_name);
            END IF;
        ELSE
            return_value = ('Error','Project or model does not exist, parameters not updated', proj_name, mod_name, new_param_1, new_param_2);
        END IF;               
        RETURN return_value;
    END;

$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION extrapolate_model_data(proj_name character varying, mod_name character varying, start_year integer, end_year integer) RETURNS record AS $$

    DECLARE 
	     return_value record;
		 model_uuid uuid;
		 
    BEGIN
        model_uuid = NULL;
		SELECT a.model_id INTO model_uuid FROM fdc_tgv_data.tgv_models m JOIN fdc_tgv_data.tgv_projects p ON 
		    m.project_id = p.project_id AND m.model_name = mod_name AND p.project_name = proj_name;   
        IF model_uuid IS NOT NULL THEN
            -- Extrapolate data...
            -- Find tidligste og seneste eksisterende dato 
			-- Find periode fra projekt data
			-- Find manglende periode
			-- Beregn alle data på basis af modeldata , periode og gem resultat i table cell_



            return_value = ('Succes','Data extrapolated for project/model', proj_name, mod_name,start_year, end_year);
		ELSE
            return_value = ('Error','Data *not* extrapolated for project/model, project or model name does not exist', proj_name, mod_name,start_year, end_year);
        END IF;               
        RETURN return_value;
    END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculate_model_year_values(proj_name character varying, mod_name character varying) RETURNS record AS $$

    DECLARE 
	     return_value record;
		 model_uuid uuid;
		 
    BEGIN
        model_uuid = NULL;
		SELECT a.model_id INTO model_uuid FROM fdc_tgv_data.tgv_models m JOIN fdc_tgv_data.tgv_projects p ON 
		    m.project_id = p.project_id AND m.model_name = mod_name AND p.project_name = proj_name;   
        IF model_uuid IS NOT NULL THEN
            -- Calculate data...
            return_value = ('Succes','Data calculated for project/model', proj_name, mod_name);
		ELSE
            return_value = ('Error','Data *not* extrapolated for project/model, project or model name does not exist', proj_name, mod_name,start_year, end_year);
        END IF;               
        RETURN return_value;
    END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculate_building_costs(proj_name character varying, mod_name character varying) RETURNS record AS $$

    DECLARE 
	     return_value record;
		 model_uuid uuid;
		 
    BEGIN
        model_uuid = NULL;
		SELECT a.model_id INTO model_uuid FROM fdc_tgv_data.tgv_models m JOIN fdc_tgv_data.tgv_projects p ON 
		    m.project_id = p.project_id AND m.model_name = mod_name AND p.project_name = proj_name;   
        IF model_uuid IS NOT NULL THEN
            -- Calculate data...
            return_value = ('Succes','Building costs calculated for project/model', proj_name, mod_name);
		ELSE
            return_value = ('Error','Building costs *not* extrapolated for project/model, project or model name does not exist', proj_name, mod_name,start_year, end_year);
        END IF;               
        RETURN return_value;
    END;

$$ LANGUAGE plpgsql;
