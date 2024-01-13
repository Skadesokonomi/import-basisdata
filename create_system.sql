-- Setup PostGIS

CREATE EXTENSION IF NOT EXISTS postgis;

-- Schemas

CREATE SCHEMA fdc_admin; -- parametre + historik på modeller
CREATE SCHEMA fdc_lookup; -- lookup data
CREATE SCHEMA fdc_sector; -- sektor data
CREATE SCHEMA fdc_flood; -- oversvømmelses data
CREATE SCHEMA fdc_values; -- parametre + historik/ oversigt over modelkørsler
CREATE SCHEMA fdc_results; -- resultater


DO $$
BEGIN
  CREATE ROLE "{fdc_read_role}"  NOINHERIT; -- kan læse data fra alle schemaer i databasenR
  EXCEPTION WHEN duplicate_object THEN RAISE NOTICE '%, skipping', SQLERRM USING ERRCODE = SQLSTATE;
END
$$;
DO $$
BEGIN
  CREATE ROLE "{fdc_model_role}" NOINHERIT; -- har alle rettigheder model schemaer
  EXCEPTION WHEN duplicate_object THEN RAISE NOTICE '%, skipping', SQLERRM USING ERRCODE = SQLSTATE;
END
$$;
DO $$
BEGIN
  CREATE ROLE "{fdc_admin_role}" NOINHERIT; -- har alle rettigheder inkl. oprettelse af nye schemaer
  EXCEPTION WHEN duplicate_object THEN RAISE NOTICE '%, skipping', SQLERRM USING ERRCODE = SQLSTATE;
END
$$;
--CREATE ROLE "{fdc_read_role}"  NOINHERIT; -- kan læse data fra alle schemaer i databasenR
--CREATE ROLE "{fdc_model_role}" NOINHERIT; -- har alle rettigheder model schemaer
--CREATE ROLE "{fdc_admin_role}" NOINHERIT; -- har alle rettigheder inkl. oprettelse af nye schemaer

-- Fjern alle standard rettigheder fra schemaer, inkl. schema "public" fra rolle "PUBLIC"
REVOKE ALL ON SCHEMA public, fdc_admin, fdc_lookup, fdc_sector, fdc_flood, fdc_values, fdc_results FROM PUBLIC;
REVOKE ALL ON DATABASE "{database_name}" FROM PUBLIC;  

-- Tildel rettigheder til de forskellige ressourcegrupper

-- Adgang til database
GRANT CONNECT, TEMP ON DATABASE "{database_name}" TO "{fdc_read_role}", "{fdc_model_role}";
GRANT ALL ON DATABASE "{database_name}" TO "{fdc_admin_role}";

-- Adgang til schemaer for read og model gruppe
GRANT USAGE ON SCHEMA public, fdc_admin, fdc_lookup, fdc_sector, fdc_flood, fdc_values, fdc_results TO "{fdc_read_role}", "{fdc_model_role}";
-- Administrator får alle rettigheder
GRANT ALL ON SCHEMA public, fdc_admin, fdc_lookup, fdc_sector, fdc_flood, fdc_values, fdc_results TO "{fdc_admin_role}";

-- Læse rettigheder til nye objekter for read gruppe
ALTER DEFAULT PRIVILEGES IN SCHEMA public, fdc_admin, fdc_lookup, fdc_sector, fdc_flood, fdc_values, fdc_results GRANT SELECT  ON TABLES    TO "{fdc_read_role}";
ALTER DEFAULT PRIVILEGES IN SCHEMA public, fdc_admin, fdc_lookup, fdc_sector, fdc_flood, fdc_values, fdc_results GRANT SELECT  ON SEQUENCES TO "{fdc_read_role}";
ALTER DEFAULT PRIVILEGES IN SCHEMA public, fdc_admin, fdc_lookup, fdc_sector, fdc_flood, fdc_values, fdc_results GRANT EXECUTE ON FUNCTIONS TO "{fdc_read_role}";

-- Alle rettigheder til nye objekter til gruppe adm
ALTER DEFAULT PRIVILEGES IN SCHEMA public, fdc_admin, fdc_lookup, fdc_sector, fdc_flood, fdc_values, fdc_results GRANT ALL ON TABLES    TO "{fdc_admin_role}";
ALTER DEFAULT PRIVILEGES IN SCHEMA public, fdc_admin, fdc_lookup, fdc_sector, fdc_flood, fdc_values, fdc_results GRANT ALL ON SEQUENCES TO "{fdc_admin_role}"; 
ALTER DEFAULT PRIVILEGES IN SCHEMA public, fdc_admin, fdc_lookup, fdc_sector, fdc_flood, fdc_values, fdc_results GRANT ALL ON FUNCTIONS TO "{fdc_admin_role}";

-- Rettigheder til nye objekter til gruppe model
ALTER DEFAULT PRIVILEGES IN SCHEMA public, fdc_admin, fdc_lookup GRANT SELECT  ON TABLES    TO "{fdc_model_role}";
ALTER DEFAULT PRIVILEGES IN SCHEMA public, fdc_admin, fdc_lookup GRANT SELECT  ON SEQUENCES TO "{fdc_model_role}";
ALTER DEFAULT PRIVILEGES IN SCHEMA public, fdc_admin, fdc_lookup GRANT EXECUTE ON FUNCTIONS TO "{fdc_model_role}";
ALTER DEFAULT PRIVILEGES IN SCHEMA fdc_sector, fdc_flood, fdc_values, fdc_results GRANT ALL ON TABLES    TO "{fdc_model_role}";
ALTER DEFAULT PRIVILEGES IN SCHEMA fdc_sector, fdc_flood, fdc_values, fdc_results GRANT ALL ON SEQUENCES TO "{fdc_model_role}"; 
ALTER DEFAULT PRIVILEGES IN SCHEMA fdc_sector, fdc_flood, fdc_values, fdc_results GRANT ALL ON FUNCTIONS TO "{fdc_model_role}";

-- creation of parameters table 
SET search_path = fdc_admin, public;

CREATE TABLE IF NOT EXISTS parametre (
    name character varying NOT NULL,
    parent character varying,
    value character varying NOT NULL,
    type character varying(1) NOT NULL,
    minval character varying NOT NULL,
    maxval character varying NOT NULL,
    lookupvalues character varying NOT NULL,
    "default" character varying NOT NULL,
    explanation character varying NOT NULL,
    sort integer NOT NULL,
    checkable "char" NOT NULL
);

TRUNCATE TABLE parametre;

-- populate table
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('General', '', '', 'G', '', '', '', '', 'Hovedgrupper til administration af grundlæggende parametre for systemet', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Cell administration', 'General', '', 'G', '', '', '', '', 'Grupper til administration af celle generering', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Name templates', 'General', '', 'G', '', '', '', '', 'Grupper til administration af celle generering', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('SQL templates', 'General', '', 'G', '', '', '', '', 'Grupper til administration af celle generering', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Hidden parameters', 'General', '', 'G', '', '', '', '', 'Grupper til administration af skjulte semipermanente parametre', 2, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Cell layername', 'Cell administration', 'celler', 'T', '', '', '', '', '', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Name of model value section', 'Name templates', 'Generelle modelværdier', 'T', '', '', '', '', '', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Clear cell layer template', 'Cell administration', 'UPDATE "{schema}"."{table}" SET val_intersect = 0.0, num_intersect = 0
', 'P', '', '', '', '', '', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Cell size', 'Cell administration', '100', 'I', '10', '1000', '50', '', '', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Delete parameter table', 'SQL templates', 'DELETE FROM {parametertable}', 'P', '', '', '', '', '', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('update cell layer', 'Cell administration', 'WITH cte AS (
  SELECT
    a.{pkey_cell} AS fid,
    sum(
      CASE 				  
        WHEN ST_GeometryType(b.{geom_value}) ILIKE ''%POINT%'' THEN b.{value_value} 				  
        WHEN ST_GeometryType(b.{geom_value}) ILIKE ''%LINE%'' THEN b.{value_value} * st_length(st_intersection(a.{geom_cell},b.{geom_value}))/st_length(b.{geom_value})				  
        WHEN ST_GeometryType(b.{geom_value}) ILIKE ''%POLYGON%'' THEN b.{value_value} * st_area(st_intersection(a.{geom_cell},b.{geom_value}))/st_area(b.{geom_value})	  
        ELSE -10000000.00      
      END
    ) as sum_value,
    count(*) as count_number
  FROM {cell_table} a JOIN {value_table} b ON st_intersects (a.{geom_cell},b.{geom_value})
  GROUP BY a.{pkey_cell}
)
UPDATE {cell_table} SET 
  val_intersect = val_intersect + sum_value, 
  num_intersect = num_intersect + count_number 
FROM cte
WHERE {cell_table}.{pkey_cell} = cte.fid; ', 'P', '', '', '', '', '', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Insert parameter table', 'SQL templates', 'INSERT INTO {parametertable} ({parametercolumns}) VALUES ({parametervalues}', 'P', '', '', '', '', '', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Fetch parameter table', 'SQL templates', 'WITH RECURSIVE tree_search AS (SELECT *, 0 AS "level" FROM {parametertable} WHERE "parent" = '''' AND name <> '''' UNION ALL SELECT t.*, ts."level"+1 AS "level" FROM {parametertable} t, tree_search ts WHERE t."parent" = ts."name") SELECT * FROM tree_search ORDER BY "level", "sort";', 'P', '', '', '', '', '', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Drop schema command', 'SQL templates', 'DROP SCHEMA {} /CASCADE', 'P', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Create schema command', 'SQL templates', 'CREATE SCHEMA {}', 'P', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Create_result_table', 'SQL templates', 'CREATE TABLE IF NOT EXISTS "{Result_schema}"."{tablename_ts}" AS {sqlquery}', 'P', '', '', '', '', 'SQL template for creating result tables', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Main groupname', 'Name templates', 'Modeller', 'T', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Group name template', 'Name templates', 'Kørsel: {time_stamp}', 'T', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Create_result_pkey', 'SQL templates', 'ALTER TABLE "{Result_schema}"."{tablename_ts}" ADD PRIMARY KEY ({pkey_column});  ', 'P', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Create_result_index', 'SQL templates', 'CREATE INDEX ON "{Result_schema}"."{tablename_ts}" USING GIST ({geom_column})', 'P', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Model_layergroup', 'Name templates', 'Resultater fra modelkørsler', 'T', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Create comment command', 'SQL templates', 'COMMENT ON {} {} IS {}', 'P', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Queries', '', '', 'G', '', '', '', '', 'Hovedgrupper til administration af Forespørgsler', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Minimum vanddybde (meter), kælder', 'Skadeberegninger, kælder', '0.1', 'R', '0.05', '10.0', '0.05', '', 'Mindste værdi for vandybde for kælder, som medtages i beregningerne ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Data', '', '', 'G', '', '', '', '', 'Hovedgruppe for administration af Tabeller', 2, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Models', '', '', 'G', '', '', '', '', 'Hovedgruppe for administration og kørsel af  Modeller', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Generelle modelværdier', 'Models', '', 'G', '', '', '', '', 'Afsnit, hvor parametre, der bruges i mange forskellige modeller, kan værdisættes', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Offentlig service', 'Models', '', 'G', '', '', '', '', 'Skademodeller for Offentlig service', 2, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Vej og trafik', 'Models', '', 'G', '', '', '', '', 'Skademodeller for Vej og trafik', 2, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Kritisk infrastruktur', 'Models', '', 'G', '', '', '', '', 'Skademodeller for Kritisk infrastruktur', 2, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Bygninger', 'Models', '', 'G', '', '', '', '', 'Skademodeller for Bygninger', 2, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Biodiversitet', 'Models', '', 'G', '', '', '', '', 'Skademodeller for Biodiversitet', 4, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Turisme', 'Models', '', 'G', '', '', '', '', 'Skademodeller for Turisme', 5, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Rekreative områder', 'Models', '', 'T', '', '', '', '', 'Skademodeller for Rekreative områder', 5, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Industri', 'Models', ' ', 'G', '', '', '', '', 'Skademodeller for Industri', 5, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Mennesker og helbred', 'Models', '', 'G', '', '', '', '', 'Skademodeller for Mennesker og helbred', 7, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Oversvømmelsesperiode (timer)', 'Vej og trafik', '24', 'I', '0', '100', '1', '', 'Her angives det antal dage, hvor vejene ikke kan benyttes pga. oversvømmelsen.', 4, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Renovationspris pr meter vej (DKK)', 'Vej og trafik', '20', 'I', '0', '1000', '10', '', 'Her angives den økonomiske omkostning til oprydning per meter vej som bliver oversvømmet. Omkostningen angives i DKK per meter.', 5, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Bredde af nabozone (meter)', 'Hidden parameters', '300.0', 'R', '0.0', '1000.0', '10.0', '', 'Maks. afstand for nabobygninger fra skaderamte bygningerder som medtages i beregningen', 3, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Medtag i risikoberegninger', 'Hidden parameters', 'Skadebeløb', 'O', '', '', 'Skadebeløb¤Værditab¤Skadebeløb og værditab¤Intet (0 kr.)', '', 'Her vælger man om det kun er skadeomkostningen eller skadeomkostning inkl. værditab for bygninger som inkluderes i risikoberegningen.', 3, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Minimum vanddybde (meter)', 'Generelle modelværdier', '0.2', 'R', '0.10', '10.0', '0.05', '', 'Her angives den minimale vanddybde på terræn som der skal til for at der opstår økonomiske tab i forbindelse med oversvømmelsen. Denne værdi angives i m, og anvendes kun for de sektorer hvor der ikke er angivet en alternativ minimum vanddybde.', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Antal tabte døgn', 'Turisme', '60', 'I', '0', '365', '5', '', 'Her angives antallet af dage hvor bygningerne som bliver berørt af den pågældende oversvømmelse ikke kan anvendes til turistformål pga. skader eller oprydning efter oversvømmelsen.  ', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Reports', '', '', 'G', '', '', '', '', 'Hovedgruppe til administration og kørsel af Rapporter', 4, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_company', 't_company', 'objectid', 'F', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_empcount_t_company', 't_company', 'aarsbes_ant', 'F', '0', '20000', '10', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_comp_id_t_company', 't_company', 'cvr_nr', 'F', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_prod_id_t_company', 't_company', 'p_nr', 'F', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_company', 't_company', 'geom', 'F', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_number_cars_t_road_traffic', 't_road_traffic', 'trafik_tal', 'F', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_road_traffic', 't_road_traffic', 'geom', 'F', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_road_traffic', 't_road_traffic', 'objectid', 'F', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Antal dage med oversvømmelse', 'Rekreative områder', '24', 'I', '0', '100', '1', '', 'Angiv antallet af dage hvor de rekreative områder ikke kan anvendes som en konsekvens af den pågældende oversvømmelse.', 3, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Faktor for værditab', 'Hidden parameters', '0.50', 'R', '0.0', '1.0', '0.1', '', 'Faktor værdi til beregning af værditab for nabobygninger ud fra værditab for skaderamte bygninger', 4, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Result_schema', 'Name templates', 'fdc_results', 'T', '', '', '', '', 'Name of schema to place result tables in', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_publicservice', 't_publicservice', 'objectid', 'F', '', '', '', '', '', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_publicservice', 't_publicservice', 'geom', 'F', '', '', '', '', '', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_tourism', 'Admin data', 'fdc_lookup.turisme', 'S', '', '', '', '', 'Parametergruppe til opslagstabel "turisme"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_build_usage', 'Admin data', 'fdc_lookup.bbr_anvendelse', 'S', '', '', '', '', 'Parametergruppe til opslagstabel "bbr-anvendelse"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_sqmprice', 'Admin data', 'fdc_lookup.kvm_pris', 'S', '', '', '', '', 'Parametergruppe til opslagstabel "kommunal kvm. pris"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_damage', 'Admin data', 'fdc_lookup.skadefunktioner', 'S', '', '', '', '', 'Parametergruppe til opslagstabel "skadesfunktioner"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_company', 'Sector data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "industri"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_publicservice', 'Sector data', '', 'S', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_road_traffic', 'Sector data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "vejnet"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_bioscore', 'Sector data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "biodiversitet"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_human_health', 'Sector data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "mennesker"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_recreative', 'Sector data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "rekreative områder"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_building', 'Sector data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "Bygninger"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_tourism', 't_tourism', 'bbr_anv_kode', 'F', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_bioscore', 't_bioscore', 'objectid', 'F', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_bioscore', 't_bioscore', 'geom', 'F', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_bioscore_t_bioscore', 't_bioscore', 'bioscore', 'F', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_human_health', 't_human_health', 'objectid', 'F', '', '', '', '', 'Field name for keyfield in Human health table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_age_t_human_health', 't_human_health', 'alder_rand', 'F', '', '', '', '', 'Field name for age field in Human health table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_human_health', 't_human_health', 'geom', 'F', '', '', '', '', 'Field name for geometry field in Human health table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_recreative', 't_recreative', 'geom', 'F', '', '', '', '', '', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_recreative', 't_recreative', 'objectid', 'F', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_infrastructure', 't_infrastructure', 'objectid', 'F', '', '', '', '', '', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_infrastructure', 't_infrastructure', 'geom', 'F', '', '', '', '', '', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_muncode_t_building', 't_building', 'komkode', 'F', '', '', '', '', 'Fieldname for municipality code for building table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_building', 't_building', 'geom', 'F', '', '', '', '', 'Field name for geometry field in building table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_building', 't_building', 'objectid', 'F', '', '', '', '', 'Field name for keyfield in Building table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_cellar_area_t_building', 't_building', 'kaelder_areal', 'F', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_usage_code_t_building', 't_building', 'bbr_anv_kode', 'F', '', '', '', '', 'Fieldname for usage code for building table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_usage_text_t_building', 't_building', 'bbr_anv_tekst', 'F', '', '', '', '', 'Fieldname for usage code for building table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_build_usage', 't_build_usage', 'bbr_anv_kode', 'F', '', '', '', '', 'Field name for keyfield in Building table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_usage_text_t_build_usage', 't_build_usage', 'bbr_anv_tekst', 'F', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_category_t_build_usage', 't_build_usage', 'skade_kategori', 'F', '', '', '', '', 'Field name for keyfield in Building table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_muncode_t_sqmprice', 't_sqmprice', 'kom_kode', 'F', '', '', '', '', 'Fieldname for municipalitycode', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_sqmprice_t_sqmprice', 't_sqmprice', 'kvm_pris', 'F', '', '', '', '', 'Fieldname for sqm price', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_damage', 't_damage', 'skade_type, skade_kategori', 'F', '', '', '', '', 'Field name for keyfield in damage function table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_category_t_damage', 't_damage', 'skade_kategori', 'F', '', '', '', '', 'Field name for keyfield in damage function table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Skadeberegning for kælder', 'Hidden parameters', 'Medtages', 'O', '', '', 'Medtages ikke¤Medtages', ' ', 'Bestemmer skadeberegning for kælder medtages i udregningen', 2, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Skadetype', 'Generelle modelværdier', 'Stormflod', 'O', '', '', 'Stormflod¤Skybrud¤Vandløb', ' ', 'Valg af økonomisk skademodel', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_type_t_damage', 't_damage', 'skade_type', 'F', '', '', '', '', 'Field name for keyfield in damage function table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Oversvømmelsesmodel, nutid', 'Generelle modelværdier', '"fdc_flood"."stormflod_t100_1981_2010"', 'Q', '', '', 't_flood_48', 't_flood', 'Vælg oversvømmelsestabel for nutidshændelse', 12, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Oversvømmelsesmodel, fremtid', 'Generelle modelværdier', '"fdc_flood"."stormflod_t100_rcp85_2071_2100"', 'Q', '', '', 't_flood_49', 't_flood', 'Vælg oversvømmelsestabel for fremtidshændelse', 13, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Returperiode, antal år', 'Generelle modelværdier', '100', 'I', '0', '1000', '10', '', 'Indtast returperioden i hele år, dvs. gennemsnitligt antal år mellem hændelser (Nutidshændelse og fremtidshændelse skal have samme returperiode)', 14, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Skadeberegninger, Bygninger gl. model', 'Hidden parameters', '', 'T', '', '', '', 'q_building', 'Skadeberegning for bygninger, forskellige skademodeller, med eller uden kælderberegning, ny metode', 11, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_building', 'q_building', 'objectid', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_building', 'q_building', 'geom', 'T', '', '', '', '', 'Field name for geometry column', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_present_q_building', 'q_building', 'skadebeloeb_nutid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_future_q_building', 'q_building', 'skadebeloeb_fremtid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_cellar_present_q_building', 'q_building', 'skadebeloeb_kaelder_nutid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_cellar_future_q_building', 'q_building', 'skadebeloeb_kaelder_fremtid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_loss_present_q_building', 'q_building', 'vaerditab_nutid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_loss_future_q_building', 'q_building', 'vaerditab_fremtid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_risk_q_building', 'q_building', 'risiko_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_building', 'Queries', '
SELECT
    b.*,
    d.{f_category_t_damage} AS skade_kategori,
    d.{f_type_t_damage} AS skade_type,
	''{Skadeberegning for kælder}'' AS kaelder_beregning,
    {Værditab, skaderamte bygninger (%)}::NUMERIC(12,2) as tab_procent,
    k.{f_sqmprice_t_sqmprice}::NUMERIC(12,2) as kvm_pris_kr,
    st_area(b.{f_geom_t_building})::NUMERIC(12,2) AS areal_byg_m2,
    n.*,
    f.*,
    r.*
    FROM {t_building} b
    LEFT JOIN {t_build_usage} u on b.{f_usage_code_t_building} = u.{f_pkey_t_build_usage}
    LEFT JOIN {t_damage} d on u.{f_category_t_build_usage} = d.{f_category_t_damage} AND d.{f_type_t_damage} = ''{Skadetype}''   
    LEFT JOIN {t_sqmprice} k on (b.{f_muncode_t_building} = k.{f_muncode_t_sqmprice}),
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_nutid,
            COALESCE(SUM(st_area(st_intersection(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, nutid}))),0)::NUMERIC(12,2) AS areal_oversvoem_nutid_m2,
            COALESCE(MIN({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
            COALESCE(MAX({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
            COALESCE(AVG({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS avg_vanddybde_nutid_cm,
            CASE WHEN COUNT (*) > 0 THEN d.b0 + st_area(b.{f_geom_t_building}) * (d.b1 * ln(GREATEST(MAX({f_depth_Oversvømmelsesmodel, nutid})*100.00, 1.0)) + d.b2) ELSE 0 END::NUMERIC(12,2) AS {f_damage_present_q_building},
            CASE WHEN COUNT (*) > 0 AND ''{Skadeberegning for kælder}'' = ''Medtages'' THEN COALESCE(b.{f_cellar_area_t_building},0.0) * d.c0 ELSE 0 END::NUMERIC(12,2) as {f_damage_cellar_present_q_building},
            CASE WHEN COUNT (*) > 0 THEN k.kvm_pris * st_area(b.{f_geom_t_building}) * {Værditab, skaderamte bygninger (%)}/100.0 ELSE 0 END::NUMERIC(12,2) as {f_loss_present_q_building}             
        FROM {Oversvømmelsesmodel, nutid} WHERE st_intersects(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, nutid}) AND {f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)}
    ) n,
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_fremtid,
            COALESCE(SUM(st_area(st_intersection(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, fremtid}))),0)::NUMERIC(12,2) AS areal_oversvoem_fremtid_m2,
            COALESCE(MIN({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS min_vanddybde_fremtid_cm,
            COALESCE(MAX({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS max_vanddybde_fremtid_cm,
            COALESCE(AVG({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS avg_vanddybde_fremtid_cm,
            CASE WHEN COUNT (*) > 0 THEN d.b0 + st_area(b.{f_geom_t_building}) * (d.b1 * ln(GREATEST(MAX({f_depth_Oversvømmelsesmodel, fremtid})*100.00, 1.0)) + d.b2) ELSE 0 END::NUMERIC(12,2) AS {f_damage_future_q_building},
            CASE WHEN COUNT (*) > 0 AND ''{Skadeberegning for kælder}'' = ''Medtages'' THEN COALESCE(b.{f_cellar_area_t_building},0.0) * d.c0 ELSE 0 END::NUMERIC(12,2) as {f_damage_cellar_future_q_building},
            CASE WHEN COUNT (*) > 0 THEN k.kvm_pris * st_area(b.{f_geom_t_building}) * {Værditab, skaderamte bygninger (%)}/100.0 ELSE 0 END::NUMERIC(12,2) as {f_loss_future_q_building}                
        FROM {Oversvømmelsesmodel, fremtid} WHERE st_intersects(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, fremtid}) AND {f_depth_Oversvømmelsesmodel, fremtid} >= {Minimum vanddybde (meter)}
    ) f,
    LATERAL (
        SELECT
          ''{Medtag i risikoberegninger}'' AS risiko_beregning,
		  {Returperiode, antal år} AS retur_periode,
          ((0.219058829 * CASE
          WHEN ''{Medtag i risikoberegninger}'' = ''Intet (0 kr.)'' THEN 0.0
          WHEN ''{Medtag i risikoberegninger}'' = ''Skadebeløb'' THEN n.{f_damage_present_q_building} + n.{f_damage_cellar_present_q_building}
          WHEN ''{Medtag i risikoberegninger}'' = ''Værditab'' THEN n.{f_loss_present_q_building}
          WHEN ''{Medtag i risikoberegninger}'' = ''Skadebeløb og værditab'' THEN n.{f_damage_present_q_building} + n.{f_damage_cellar_present_q_building} + n.{f_loss_present_q_building} 
          END + 
          0.089925625 * CASE
          WHEN ''{Medtag i risikoberegninger}'' = ''Intet (0 kr.)'' THEN 0.0
          WHEN ''{Medtag i risikoberegninger}'' = ''Skadebeløb'' THEN f.{f_damage_future_q_building} + f.{f_damage_cellar_future_q_building}
          WHEN ''{Medtag i risikoberegninger}'' = ''Værditab'' THEN f.{f_loss_future_q_building}
          WHEN ''{Medtag i risikoberegninger}'' = ''Skadebeløb og værditab'' THEN f.{f_damage_future_q_building} + f.{f_damage_cellar_future_q_building} + f.{f_loss_future_q_building} 
          END)/{Returperiode, antal år})::NUMERIC(12,2) AS {f_risk_q_building},
          '''' AS omraade
    ) r
    WHERE f.cnt_oversvoem_fremtid > 0 OR n.cnt_oversvoem_nutid > 0', 'P', '', '', '', '', 'SQL template for buildings new model ', 8, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Skadesberegning, Rekreative områder', 'Rekreative områder', '', 'T', '', '', '', 'q_recreative', 'Sæt hak såfremt der skal beregnes økonomiske tab for overnatningssteder som anvendes til turistformål. De berørte bygninger vises geografisk på et kort.  ', 10, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_recreative', 'q_recreative', 'id', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_recreative', 'q_recreative', 'geom', 'T', '', '', '', '', 'Field name for geometry column', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_present_q_recreative', 'q_recreative', 'skadebeloeb_nutid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_future_q_recreative', 'q_recreative', 'skadebeloeb_fremtid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_risk_q_recreative', 'q_recreative', 'risiko_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_recreative', 'Queries', '
SELECT 
    b.*,
    {Antal dage med oversvømmelse} AS periode_dage, 
    st_area(b.{f_geom_t_recreative})::NUMERIC(12,2) AS areal_m2,
    n.*,
    f.*,
    h.*,
    r.*
    FROM {t_recreative} b,
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_nutid,
            COALESCE((SUM(st_area(st_intersection(b.{f_geom_t_recreative},{f_geom_Oversvømmelsesmodel, nutid})))),0)::NUMERIC(12,2) AS areal_oversvoem_nutid_m2,
            COALESCE((MIN({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
            COALESCE((MAX({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
            COALESCE((AVG({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS avg_vanddybde_nutid_cm
        FROM {Oversvømmelsesmodel, nutid} WHERE st_intersects(b.{f_geom_t_recreative},{f_geom_Oversvømmelsesmodel, nutid}) AND {f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)}
    ) n,
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_fremtid,
            COALESCE((SUM(st_area(st_intersection(b.{f_geom_t_recreative},{f_geom_Oversvømmelsesmodel, fremtid})))),0)::NUMERIC(12,2) AS areal_oversvoem_fremtid_m2,
            COALESCE((MIN({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS min_vanddybde_fremtid_cm,
            COALESCE((MAX({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS max_vanddybde_fremtid_cm,
            COALESCE((AVG({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS avg_vanddybde_fremtid_cm
        FROM {Oversvømmelsesmodel, fremtid} WHERE st_intersects(b.{f_geom_t_recreative},{f_geom_Oversvømmelsesmodel, fremtid}) AND {f_depth_Oversvømmelsesmodel, fremtid} >= {Minimum vanddybde (meter)}
    ) f,
    LATERAL (
        SELECT
            (100.0 * n.areal_oversvoem_nutid_m2/st_area(b.{f_geom_t_recreative}))::NUMERIC(12,2) AS oversvoem_nutid_pct,
            (100.0 * f.areal_oversvoem_fremtid_m2/st_area(b.{f_geom_t_recreative}))::NUMERIC(12,2) AS oversvoem_fremtid_pct,
            (({Antal dage med oversvømmelse}/365.0) * (n.areal_oversvoem_nutid_m2/st_area(b.{f_geom_t_recreative})) * b.valuationk)::NUMERIC(12,2)  AS {f_damage_present_q_recreative},		    
            (({Antal dage med oversvømmelse}/365.0) * (f.areal_oversvoem_fremtid_m2/st_area(b.{f_geom_t_recreative})) * b.valuationk)::NUMERIC(12,2)  AS {f_damage_future_q_recreative}		    
    ) h,
    LATERAL (
        SELECT
            ''{Medtag i risikoberegninger}'' AS risiko_beregning,
		    {Returperiode, antal år} AS retur_periode,
            ((0.219058829 * CASE WHEN ''{Medtag i risikoberegninger}'' IN (''Skadebeløb'',''Skadebeløb og værditab'') THEN 
			    h.{f_damage_present_q_recreative} ELSE 0 END +
			0.089925625 * CASE WHEN ''{Medtag i risikoberegninger}'' IN (''Skadebeløb'',''Skadebeløb og værditab'') THEN
			    h.{f_damage_future_q_recreative} ELSE 0 END)/{Returperiode, antal år})::NUMERIC(12,2) AS {f_risk_q_recreative},
            '''' AS omraade
    ) r
    WHERE f.cnt_oversvoem_fremtid > 0 OR n.cnt_oversvoem_nutid > 0
', 'P', '', '', '', '', 'SQL template for recreative new model ', 8, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Industri, personale i bygninger', 'Industri', ' ', 'T', '', '', '', 'q_comp_build', 'Sæt hak såfremt modellen skal identificere de virksomheder som bliver berørt af den pågældende oversvømmelse, og angive antallet af medarbejdere per virksomhed.', 10, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_comp_build', 'q_comp_build', 'rowid', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_comp_build', 'q_comp_build', 'geom', 'T', '', '', '', '', 'Field name for geometry column', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Biodiversitet, kort', 'Biodiversitet', '', 'T', '', '', '', 'q_bioscore_spatial', 'Sæt hak såfremt modellen skal identificere særlige levesteder for rødlistede arter som bliver berørt i forbindelse med den pågældende oversvømmelseshændelse. Her vises levestederne geografisk på et kort.', 10, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_bioscore_spatial', 'q_bioscore_spatial', 'id', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_bioscore_spatial', 'q_bioscore_spatial', 'geom', 'T', '', '', '', '', 'Field name for geometry column', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_risk_q_road_traffic', 'q_road_traffic', 'risiko_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_present_q_road_traffic', 'q_road_traffic', 'pris_total_nutid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_future_q_road_traffic', 'q_road_traffic', 'pris_total_fremtid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_road_traffic', 'q_road_traffic', 'id', 'T', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_road_traffic', 'q_road_traffic', 'geom', 'T', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Skadeberegning, vej og trafik', 'Vej og trafik', '', 'T', '', '', '', 'q_road_traffic', 'Sæt hak såfremt der skal beregnes økonomiske tab for vej og trafik i forbindelse med den pågældende oversvømmelseshændelse.', 10, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_road_traffic', 'Queries', '
SELECT 
    b.*,
    n.*,
    f.*,
    {Oversvømmelsesperiode (timer)} AS blokering_timer,
    0.3 AS vanddybde_bloker_m,
    0.075 AS vanddybde_min_m,
	{Renovationspris pr meter vej (DKK)} AS pris_renovation_kr_m,
    h.*,
	i.*,
    r.*
    FROM {t_road_traffic} b,
    LATERAL (
        SELECT
            st_length(b.{f_geom_t_road_traffic})::NUMERIC(12,2) AS laengde_org_m,
            COUNT (*) AS cnt_oversvoem_nutid,
            COALESCE((SUM(st_length(st_intersection(b.{f_geom_t_road_traffic},{f_geom_Oversvømmelsesmodel, nutid})))),0)::NUMERIC(12,2) AS laengde_oversvoem_nutid_m,
            COALESCE((MIN({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
            COALESCE((MAX({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
            COALESCE((AVG({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS avg_vanddybde_nutid_cm
        FROM {Oversvømmelsesmodel, nutid} WHERE st_intersects(b.{f_geom_t_road_traffic},{f_geom_Oversvømmelsesmodel, nutid}) AND {f_depth_Oversvømmelsesmodel, nutid} >= 0.075
    ) n,
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_fremtid,
            COALESCE((SUM(st_length(st_intersection(b.{f_geom_t_road_traffic},{f_geom_Oversvømmelsesmodel, fremtid})))),0)::NUMERIC(12,2) AS laengde_oversvoem_fremtid_m,
            COALESCE((MIN({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS min_vanddybde_fremtid_cm,
            COALESCE((MAX({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS max_vanddybde_fremtid_cm,
            COALESCE((AVG({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS avg_vanddybde_fremtid_cm
        FROM {Oversvømmelsesmodel, fremtid} WHERE st_intersects(b.{f_geom_t_road_traffic},{f_geom_Oversvømmelsesmodel, fremtid}) AND {f_depth_Oversvømmelsesmodel, fremtid} >= 0.075
    ) f,
    LATERAL (
        SELECT
            CASE WHEN n.avg_vanddybde_nutid_cm >= 30.0 THEN 0.0 ELSE 0.0009 * (n.avg_vanddybde_nutid_cm*10.0)^2.0 - 0.5529 * n.avg_vanddybde_nutid_cm*10.0 + 86.9448 END::NUMERIC(12,2) AS hastighed_red_nutid_km_time,
            CASE WHEN f.avg_vanddybde_fremtid_cm >= 30.0 THEN 0.0 ELSE 0.0009 * (f.avg_vanddybde_fremtid_cm*10.0)^2.0 - 0.5529 * f.avg_vanddybde_fremtid_cm*10.0 + 86.9448 END::NUMERIC(12,2) AS hastighed_red_fremtid_km_time,
            n.laengde_oversvoem_nutid_m * {Renovationspris pr meter vej (DKK)} AS skade_renovation_nutid_kr,
            f.laengde_oversvoem_fremtid_m * {Renovationspris pr meter vej (DKK)} AS skade_renovation_fremtid_kr
    ) h,
    LATERAL (
        SELECT
            CASE WHEN h.hastighed_red_nutid_km_time > 50.0 THEN 0.0 ELSE (68.8 - 1.376 * h.hastighed_red_nutid_km_time) * ({Oversvømmelsesperiode (timer)} / 24.0) * n.laengde_org_m * (b.{f_number_cars_t_road_traffic}/6200.00)*2.0 END::NUMERIC(12,2) AS skade_transport_nutid_kr,
            CASE WHEN h.hastighed_red_fremtid_km_time > 50.0 THEN 0.0 ELSE (68.8 - 1.376 * h.hastighed_red_fremtid_km_time) * ({Oversvømmelsesperiode (timer)} / 24.0) * n.laengde_org_m * (b.{f_number_cars_t_road_traffic}/6200.00)*2.0 END::NUMERIC(12,2) AS skade_transport_fremtid_kr
    ) i,
    LATERAL (
        SELECT
		    h.skade_renovation_nutid_kr + i.skade_transport_nutid_kr AS {f_damage_present_q_road_traffic},
		    h.skade_renovation_fremtid_kr + i.skade_transport_fremtid_kr AS {f_damage_future_q_road_traffic},
            ''{Medtag i risikoberegninger}'' AS risiko_beregning,
		    {Returperiode, antal år} AS retur_periode,
            ((0.219058829 * CASE WHEN ''{Medtag i risikoberegninger}'' IN (''Skadebeløb'',''Skadebeløb og værditab'') THEN 
			    h.skade_renovation_nutid_kr + i.skade_transport_nutid_kr ELSE 0 END +
			0.089925625 * CASE WHEN ''{Medtag i risikoberegninger}'' IN (''Skadebeløb'',''Skadebeløb og værditab'') THEN
			    h.skade_renovation_fremtid_kr + i.skade_transport_fremtid_kr ELSE 0 END)/{Returperiode, antal år})::NUMERIC(12,2) AS {f_risk_q_road_traffic},
            '''' AS omraade
    ) r
    WHERE f.cnt_oversvoem_fremtid > 0 OR n.cnt_oversvoem_nutid > 0
', 'P', '', '', '', '', 'SQL template for road traffic new model ', 8, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_surrounding_loss', 'q_surrounding_loss', 'objectid', 'T', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_surrounding_loss', 'q_surrounding_loss', 'geom', 'T', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_risk_q_surrounding_loss', 'q_surrounding_loss', 'risiko_kr', 'T', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_loss_future_q_surrounding_loss', 'q_surrounding_loss', 'vaerditab_fremtid_kr', 'T', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_loss_present_q_surrounding_loss', 'q_surrounding_loss', 'vaerditab_nutid_kr', 'T', '', '', '', '', '', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_surrounding_loss', 'Queries', '
WITH 
    of AS (SELECT b.{f_pkey_t_building}, b.{f_geom_t_building} FROM {t_building} b WHERE EXISTS ( SELECT 1 FROM {Oversvømmelsesmodel, fremtid} f WHERE st_intersects (f.{f_geom_Oversvømmelsesmodel, fremtid}, b.{f_geom_t_building}) AND  f.{f_depth_Oversvømmelsesmodel, fremtid} >= {Minimum vanddybde (meter)})),
    op AS (SELECT b.{f_pkey_t_building}, b.{f_geom_t_building} FROM {t_building} b WHERE EXISTS ( SELECT 1 FROM {Oversvømmelsesmodel, nutid} f WHERE st_intersects (f.{f_geom_Oversvømmelsesmodel, nutid}, b.{f_geom_t_building}) AND  f.{f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)}))

SELECT 
    x.*,
    st_area(x.{f_geom_t_building})::NUMERIC(12,2) AS areal_byg_m2,
    k.{f_sqmprice_t_sqmprice}::NUMERIC(12,2) AS kvm_pris_kr,
    ({Værditab, skaderamte bygninger (%)}*{Faktor for værditab})::NUMERIC(12,2) AS tab_procent,
    CASE WHEN y.{f_pkey_t_building} IS NULL THEN 0.0 ELSE k.{f_sqmprice_t_sqmprice} * st_area(x.{f_geom_t_building}) * {Værditab, skaderamte bygninger (%)}*{Faktor for værditab} / 100.0 END::NUMERIC(12,2) AS {f_loss_future_q_surrounding_loss},
    CASE WHEN z.{f_pkey_t_building} IS NULL THEN 0.0 ELSE k.{f_sqmprice_t_sqmprice} * st_area(x.{f_geom_t_building}) * {Værditab, skaderamte bygninger (%)}*{Faktor for værditab} / 100.0 END::NUMERIC(12,2) AS {f_loss_present_q_surrounding_loss},
    ''{Medtag i risikoberegninger}'' AS risiko_beregning,
    {Returperiode, antal år} AS retur_periode,
    ((
	    0.219058829 * 
	    CASE 
		    WHEN ''{Medtag i risikoberegninger}'' IN (''Værditab'',''Skadebeløb og værditab'') THEN 
                CASE 
			        WHEN z.{f_pkey_t_building} IS NULL THEN 0.0 
			        ELSE k.{f_sqmprice_t_sqmprice} * st_area(x.{f_geom_t_building}) * {Værditab, skaderamte bygninger (%)}*{Faktor for værditab} / 100.0 
                END
            ELSE 0 
		END +
	    0.089925625 * 
	    CASE 
		    WHEN ''{Medtag i risikoberegninger}'' IN (''Værditab'',''Skadebeløb og værditab'') THEN
	            CASE 
				    WHEN y.{f_pkey_t_building} IS NULL THEN 0.0 
					ELSE k.{f_sqmprice_t_sqmprice} * st_area(x.{f_geom_t_building}) * {Værditab, skaderamte bygninger (%)}*{Faktor for værditab} / 100.0 
				END
	        ELSE 0 
        END)/{Returperiode, antal år})::NUMERIC(12,2) AS {f_risk_q_surrounding_loss},
    '''' AS omraade
FROM {t_building} x 
LEFT JOIN (SELECT DISTINCT c.{f_pkey_t_building} FROM {t_building} c, of WHERE c.{f_pkey_t_building} NOT IN (SELECT {f_pkey_t_building} from of) and st_dwithin(of.{f_geom_t_building},c.{f_geom_t_building},300.)) y ON x.{f_pkey_t_building} = y.{f_pkey_t_building} 
LEFT JOIN (SELECT DISTINCT c.{f_pkey_t_building} FROM {t_building} c, op WHERE c.{f_pkey_t_building} NOT IN (SELECT {f_pkey_t_building} from op) and st_dwithin(op.{f_geom_t_building},c.{f_geom_t_building},300.)) z ON x.{f_pkey_t_building} = z.{f_pkey_t_building} 
LEFT JOIN {t_sqmprice} k ON k.kom_kode = x.komkode 
WHERE y.{f_pkey_t_building} IS NOT NULL OR z.{f_pkey_t_building} IS NOT NULL
', 'P', '', '', '', '', 'SQL template for surrounding loss - new model ', 8, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Værditab nabobygninger', 'Hidden parameters', '', 'T', '', '', '', 'q_surrounding_loss', '', 12, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Admin data', 'Data', '', 'G', '', '', '', '', 'Gruppe for administration af Lookup tabeller', 2, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Flood data', 'Data', '', 'G', '', '', '', '', 'Gruppe for administration af Oversvømmelses tabeller', 2, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Sector data', 'Data', '', 'G', '', '', '', '', 'Gruppe for administration af Sektor tabeller', 2, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_01', 't_flood_01', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_02', 't_flood_02', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_03', 't_flood_03', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_04', 't_flood_04', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_05', 't_flood_05', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_06', 't_flood_06', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_07', 't_flood_07', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_08', 't_flood_08', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_09', 't_flood_09', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_10', 't_flood_10', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_11', 't_flood_11', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_12', 't_flood_12', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_13', 't_flood_13', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_14', 't_flood_14', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_15', 't_flood_15', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_16', 't_flood_16', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_17', 't_flood_17', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_18', 't_flood_18', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_19', 't_flood_19', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_20', 't_flood_20', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_21', 't_flood_21', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_22', 't_flood_22', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_23', 't_flood_23', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_24', 't_flood_24', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_25', 't_flood_25', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_26', 't_flood_26', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_27', 't_flood_27', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_28', 't_flood_28', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_29', 't_flood_29', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_30', 't_flood_30', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_31', 't_flood_31', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_32', 't_flood_32', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_33', 't_flood_33', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_34', 't_flood_34', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_35', 't_flood_35', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_36', 't_flood_36', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_37', 't_flood_37', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_38', 't_flood_38', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_39', 't_flood_39', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_40', 't_flood_40', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_41', 't_flood_41', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_42', 't_flood_42', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_43', 't_flood_43', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_44', 't_flood_44', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_45', 't_flood_45', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_46', 't_flood_46', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_47', 't_flood_47', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_48', 't_flood_48', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_49', 't_flood_49', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_flood_50', 't_flood_50', 'fid', 'F', '', '', '', '', 'Field name for primary key field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_01', 't_flood_01', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_02', 't_flood_02', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_03', 't_flood_03', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_04', 't_flood_04', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_05', 't_flood_05', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_06', 't_flood_06', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_07', 't_flood_07', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_08', 't_flood_08', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_09', 't_flood_09', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_10', 't_flood_10', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_11', 't_flood_11', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_12', 't_flood_12', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_13', 't_flood_13', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_14', 't_flood_14', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_15', 't_flood_15', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_16', 't_flood_16', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_17', 't_flood_17', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_18', 't_flood_18', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_19', 't_flood_19', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_20', 't_flood_20', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_21', 't_flood_21', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_22', 't_flood_22', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_23', 't_flood_23', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_24', 't_flood_24', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_25', 't_flood_25', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_26', 't_flood_26', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_27', 't_flood_27', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_28', 't_flood_28', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_29', 't_flood_29', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_30', 't_flood_30', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_31', 't_flood_31', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_32', 't_flood_32', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_33', 't_flood_33', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_34', 't_flood_34', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_35', 't_flood_35', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_36', 't_flood_36', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_37', 't_flood_37', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_38', 't_flood_38', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_39', 't_flood_39', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_40', 't_flood_40', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_41', 't_flood_41', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_42', 't_flood_42', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_43', 't_flood_43', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_44', 't_flood_44', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_45', 't_flood_45', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_46', 't_flood_46', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_47', 't_flood_47', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_48', 't_flood_48', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_49', 't_flood_49', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_flood_50', 't_flood_50', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_01', 't_flood_01', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_02', 't_flood_02', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_03', 't_flood_03', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_04', 't_flood_04', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_05', 't_flood_05', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_06', 't_flood_06', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_07', 't_flood_07', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_08', 't_flood_08', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_09', 't_flood_09', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_10', 't_flood_10', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_11', 't_flood_11', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_12', 't_flood_12', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_13', 't_flood_13', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_14', 't_flood_14', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_15', 't_flood_15', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_16', 't_flood_16', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_17', 't_flood_17', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_18', 't_flood_18', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_19', 't_flood_19', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_20', 't_flood_20', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_21', 't_flood_21', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_22', 't_flood_22', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_23', 't_flood_23', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_24', 't_flood_24', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_25', 't_flood_25', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_26', 't_flood_26', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_27', 't_flood_27', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_28', 't_flood_28', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_29', 't_flood_29', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_30', 't_flood_30', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_31', 't_flood_31', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_32', 't_flood_32', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_33', 't_flood_33', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_34', 't_flood_34', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_35', 't_flood_35', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_36', 't_flood_36', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_37', 't_flood_37', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_38', 't_flood_38', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_39', 't_flood_39', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_40', 't_flood_40', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_41', 't_flood_41', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_42', 't_flood_42', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_43', 't_flood_43', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_44', 't_flood_44', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_45', 't_flood_45', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_46', 't_flood_46', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_47', 't_flood_47', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_48', 't_flood_48', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_49', 't_flood_49', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_depth_t_flood_50', 't_flood_50', 'vanddybde_m', 'F', '', '', '', '', 'Field name for detph field in flood table ', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_infrastructure', 'Sector data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "kritisk infrastruktur"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_01', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_02', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 2, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_03', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 3, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_04', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 4, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_05', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 5, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_06', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 6, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_07', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 7, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_08', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 8, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_09', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 9, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_10', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_11', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 11, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_12', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 12, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_13', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 13, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_14', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 14, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_15', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 15, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_16', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 16, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_17', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 17, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_18', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 18, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_19', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 19, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_20', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 20, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_21', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 21, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_22', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 22, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_23', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 23, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_24', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 24, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_25', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 25, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_26', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 26, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_27', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 27, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_28', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 28, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_29', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 29, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_30', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 30, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_31', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 31, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_32', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 32, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_33', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 33, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_34', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 34, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_35', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 35, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_36', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 36, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_37', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 37, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_38', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 38, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_39', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 39, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_40', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 40, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_41', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 41, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_42', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 42, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_43', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 43, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_44', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 44, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_45', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 45, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_46', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 46, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_47', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 47, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_48', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 48, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_49', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 49, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_flood_50', 'Flood data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "oversvømmelser"', 50, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Værditab, skaderamte bygninger (%)', 'Hidden parameters', '4', 'R', '0.0', '100.0', '5.0', '', 'Her angives størrelsen på reduktionen i salgspris for de bygninger som bliver berørt af den pågældende oversvømmelse. Tabet beregnes som en procentsats, som angives af brugeren, af den gennemsnitlige kommunale m2 pris for solgte boliger i løbet af de seneste år. Det anbefales at anvende værdien 10% såfremt man ikke har bedre data.', 3, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Create cell layer template', 'Cell administration', 'CREATE TABLE IF NOT EXISTS {celltable} AS
  WITH g AS (
    SELECT (
      st_squaregrid({cellsize}, st_geomfromewkt(''SRID={epsg}; POLYGON(({xmin} {ymin},{xmax} {ymin},{xmax} {ymax},{xmin} {ymax},{xmin} {ymin}))''))
	).*
  )
  SELECT
    row_number() OVER () AS fid,
    i,
    j,
    {cellsize} AS  cellsize, 
    CASE WHEN {cellsize} < 1000 THEN {cellsize}::INTEGER::TEXT || ''m_'' ELSE ({cellsize}/1000)::INTEGER::TEXT || ''km_'' END || 
	    j::TEXT || ''_'' || i::TEXT AS cellname,
    0.0::NUMERIC(12,2) AS val_intersect, 
    0 AS num_intersect,
    st_force2d(geom)::Geometry(Polygon,25832) AS geom	
  FROM g;
ALTER TABLE {celltable} ADD PRIMARY KEY(fid);
CREATE INDEX ON {celltable} USING GIST(geom);', 'P', '', '', '', '', '', 1, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_bioscore_spatial', 'Queries', '
SELECT
    c.*,
	st_area(c.{f_geom_t_bioscore})::NUMERIC(12,2) AS areal_m2,
    n.*,
    f.*,
    {Returperiode, antal år} AS retur_periode,
    '''' AS omraade
FROM {t_bioscore} c,     
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_nutid,
            COALESCE((SUM(st_area(st_intersection(c.{f_geom_t_bioscore},{f_geom_Oversvømmelsesmodel, nutid})))),0)::NUMERIC(12,2) AS areal_oversvoem_nutid_m2,
            COALESCE((MIN({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
            COALESCE((MAX({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
            COALESCE((AVG({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS avg_vanddybde_nutid_cm
        FROM {Oversvømmelsesmodel, nutid} WHERE {f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)} AND st_intersects(c.{f_geom_t_bioscore},{f_geom_Oversvømmelsesmodel, nutid})
    ) n,
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_fremtid,
            COALESCE((SUM(st_area(st_intersection(c.{f_geom_t_bioscore},{f_geom_Oversvømmelsesmodel, fremtid})))),0)::NUMERIC(12,2) AS areal_oversvoem_fremtid_m2,
            COALESCE((MIN({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS min_vanddybde_fremtid_cm,
            COALESCE((MAX({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS max_vanddybde_fremtid_cm,
            COALESCE((AVG({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS avg_vanddybde_fremtid_cm
        FROM {Oversvømmelsesmodel, fremtid} WHERE {f_depth_Oversvømmelsesmodel, fremtid} >= {Minimum vanddybde (meter)} AND st_intersects(c.{f_geom_t_bioscore},{f_geom_Oversvømmelsesmodel, fremtid})
    ) f
WHERE n.cnt_oversvoem_nutid > 0 OR f.cnt_oversvoem_fremtid > 0 
', 'P', '', '', '', '', 'SQL template for bioscore spatial - new model ', 8, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_comp_build', 'Queries', '
SELECT
    row_number() OVER () as {f_pkey_q_comp_build},
    c.*,
    b.{f_pkey_t_building} AS byg_id,
    b.{f_muncode_t_building} AS kom_kode,
    b.{f_usage_code_t_building} AS bbr_anv_kode,
    b.{f_usage_text_t_building} AS bbr_anv_tekst,
    n.*,
    f.*,
    {Returperiode, antal år} AS retur_periode,
    '''' AS omraade
FROM {t_company} c LEFT JOIN {t_building} b ON st_within(c.{f_geom_t_company},b.{f_geom_t_building}),     
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_nutid,
            COALESCE((MIN({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
            COALESCE((MAX({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
            COALESCE((AVG({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS avg_vanddybde_nutid_cm
        FROM {Oversvømmelsesmodel, nutid} WHERE {f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)} AND 
		    (b.{f_pkey_t_building} IS NOT NULL AND st_intersects(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, nutid}) OR
			 b.{f_pkey_t_building} IS NULL     AND st_within(c.{f_geom_t_company},{f_geom_Oversvømmelsesmodel, nutid}))
    ) n,
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_fremtid,
            COALESCE((MIN({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS min_vanddybde_fremtid_cm,
            COALESCE((MAX({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS max_vanddybde_fremtid_cm,
            COALESCE((AVG({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS avg_vanddybde_fremtid_cm
        FROM {Oversvømmelsesmodel, fremtid} WHERE {f_depth_Oversvømmelsesmodel, fremtid} >= {Minimum vanddybde (meter)} AND 
		    (b.{f_pkey_t_building} IS NOT NULL AND st_intersects(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, fremtid}) OR
			 b.{f_pkey_t_building} IS NULL     AND st_within(c.{f_geom_t_company},{f_geom_Oversvømmelsesmodel, fremtid}))
    ) f
WHERE n.cnt_oversvoem_nutid > 0 OR f.cnt_oversvoem_fremtid > 0 
', 'P', '', '', '', '', 'SQL template for human health new model ', 8, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Oversvømmet infrastruktur', 'Kritisk infrastruktur', '', 'T', '', '', '', 'q_infrastructure', 'Udpegning af oversvømmet kritisk infrastruktur. Den berørte infrastruktur vises geografisk på et kort.  ', 10, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_infrastructure', 'q_infrastructure', 'objectid', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_infrastructure', 'q_infrastructure', 'geom', 'T', '', '', '', '', 'Field name for geometry column', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_infrastructure', 'Queries', '
SELECT DISTINCT ON (o.{f_pkey_t_infrastructure}) 
    o.*,
    n.*,
    f.*,
    {Returperiode, antal år} AS retur_periode,
    '''' AS omraade
    FROM {t_infrastructure} o,
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_nutid,
            COALESCE(SUM(st_area(st_intersection(o.{f_geom_t_infrastructure},{f_geom_Oversvømmelsesmodel, nutid}))),0)::NUMERIC(12,2) AS areal_oversvoem_nutid_m2,
            COALESCE(SUM(st_length(st_intersection(o.{f_geom_t_infrastructure},{f_geom_Oversvømmelsesmodel, nutid}))),0)::NUMERIC(12,2) AS laengde_oversvoem_nutid_m2,
            COALESCE(MIN({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
            COALESCE(MAX({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
            COALESCE(AVG({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS avg_vanddybde_nutid_cm
        FROM {Oversvømmelsesmodel, nutid} WHERE {f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)} AND st_intersects(o.{f_geom_t_infrastructure},{f_geom_Oversvømmelsesmodel, nutid}) 
    ) n,
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_fremtid,
            COALESCE(SUM(st_area(st_intersection(o.{f_geom_t_infrastructure},{f_geom_Oversvømmelsesmodel, fremtid}))),0)::NUMERIC(12,2) AS areal_oversvoem_fremtid_m2,
            COALESCE(SUM(st_length(st_intersection(o.{f_geom_t_infrastructure},{f_geom_Oversvømmelsesmodel, fremtid}))),0)::NUMERIC(12,2) AS laengde_oversvoem_fremtid_m2,
            COALESCE(MIN({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS min_vanddybde_fremtid_cm,
            COALESCE(MAX({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS max_vanddybde_fremtid_cm,
            COALESCE(AVG({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS avg_vanddybde_fremtid_cm
        FROM {Oversvømmelsesmodel, fremtid} WHERE {f_depth_Oversvømmelsesmodel, fremtid} >= {Minimum vanddybde (meter)} AND st_intersects(o.{f_geom_t_infrastructure},{f_geom_Oversvømmelsesmodel, fremtid}) 
    ) f
    WHERE f.cnt_oversvoem_fremtid > 0 OR n.cnt_oversvoem_nutid > 0
', 'P', '', '', '', '', 'SQL template for infrastructure new model ', 8, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Oversvømmet offentlig service', 'Offentlig service', '', 'T', '', '', '', 'q_publicservice', 'Udpegning af oversvømmet kritisk infrastruktur. Den berørte infrastruktur vises geografisk på et kort.  ', 10, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_publicservice', 'q_publicservice', 'objectid', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_publicservice', 'q_publicservice', 'geom', 'T', '', '', '', '', 'Field name for geometry column', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_publicservice', 'Queries', '
SELECT DISTINCT ON (o.{f_pkey_t_publicservice}) 
    o.*,
    n.*,
    f.*,
	{Returperiode, antal år} AS retur_periode,
    '''' AS omraade
    FROM {t_publicservice} o,
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_nutid,
            COALESCE(SUM(st_area(st_intersection(o.{f_geom_t_publicservice},{f_geom_Oversvømmelsesmodel, nutid}))),0)::NUMERIC(12,2) AS areal_oversvoem_nutid_m2,
            COALESCE(SUM(st_length(st_intersection(o.{f_geom_t_publicservice},{f_geom_Oversvømmelsesmodel, nutid}))),0)::NUMERIC(12,2) AS laengde_oversvoem_nutid_m2,
            COALESCE(MIN({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
            COALESCE(MAX({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
            COALESCE(AVG({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS avg_vanddybde_nutid_cm
        FROM {Oversvømmelsesmodel, nutid} WHERE {f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)} AND st_intersects(o.{f_geom_t_publicservice},{f_geom_Oversvømmelsesmodel, nutid}) 
    ) n,
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_fremtid,
            COALESCE(SUM(st_area(st_intersection(o.{f_geom_t_publicservice},{f_geom_Oversvømmelsesmodel, fremtid}))),0)::NUMERIC(12,2) AS areal_oversvoem_fremtid_m2,
            COALESCE(SUM(st_length(st_intersection(o.{f_geom_t_publicservice},{f_geom_Oversvømmelsesmodel, fremtid}))),0)::NUMERIC(12,2) AS laengde_oversvoem_fremtid_m2,
            COALESCE(MIN({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS min_vanddybde_fremtid_cm,
            COALESCE(MAX({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS max_vanddybde_fremtid_cm,
            COALESCE(AVG({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS avg_vanddybde_fremtid_cm
        FROM {Oversvømmelsesmodel, fremtid} WHERE {f_depth_Oversvømmelsesmodel, fremtid} >= {Minimum vanddybde (meter)} AND st_intersects(o.{f_geom_t_publicservice},{f_geom_Oversvømmelsesmodel, fremtid}) 
    ) f
    WHERE f.cnt_oversvoem_fremtid > 0 OR n.cnt_oversvoem_nutid > 0
', 'P', '', '', '', '', 'SQL template for public service new model ', 8, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Landbrug', 'Models', '', 'G', '', '', '', '', 'Skademodeller for landbrug', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Oversvømmede landbrugs arealer', 'Landbrug', '', 'T', '', '', '', 'q_agriculture', 'Sæt hak såfremt der skal beregnes økonomiske tab for oversvømmede landbrugsarealer.', 10, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_agriculture', 'q_agriculture', 'fid', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_agriculture', 'q_agriculture', 'geom', 'T', '', '', '', '', 'Field name for geometry column', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_present_q_agriculture', 'q_agriculture', 'skadebeloeb_nutid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_future_q_agriculture', 'q_agriculture', 'skadebeloeb_fremtid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_risk_q_agriculture', 'q_agriculture', 'risiko_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_agriculture', 'Sector data', '', 'S', '', '', '', '', 'Parametergruppe til tabel "Landbrug"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_agr_cat', 'Admin data', 'fdc_lookup.afgroede_kategori', 'S', '', '', '', '', 'Parametergruppe til opslagstabel "afgrøde-kategori"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('t_agr_price', 'Admin data', 'fdc_lookup.afgroede_pris', 'S', '', '', '', '', 'Parametergruppe til opslagstabel "afgrøde-pris"', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_agriculture', 't_agriculture', 'fid', 'F', '', '', '', '', 'Name of primary keyfield for query', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_t_agriculture', 't_agriculture', 'geom', 'F', '', '', '', '', 'Field name for geometry column', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_afgcode_t_agriculture', 't_agriculture', 'afgkode', 'F', '', '', '', '', 'Field name for agr code column', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_agr_cat', 't_agr_cat', 'afgroedekode', 'F', '', '', '', '', 'Name of primary keyfield for query', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pcat_t_agr_cat', 't_agr_cat', 'priskategori', 'F', '', '', '', '', 'Name of field for price category', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_t_agr_price', 't_agr_price', 'priskategori', 'F', '', '', '', '', 'Name of primary keyfield for query', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_price_t_agr_price', 't_agr_price', 'pris', 'F', '', '', '', '', 'Name of field for price in øre', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_agriculture', 'Queries', '
SELECT
    b.*,
    k.afgroedegruppe,
    k.afgroedekategori,
    p.*,
    n.*,
    areal_oversvoem_nutid_m2 * p.{f_price_t_agr_price} /100.00 AS {f_damage_present_q_agriculture},
    f.*,
    areal_oversvoem_fremtid_m2 * p.{f_price_t_agr_price} /100.00 AS {f_damage_future_q_agriculture},
    r.*
    FROM {t_agriculture} b
    LEFT JOIN {t_agr_cat} k ON k.{f_pkey_t_agr_cat} = b.{f_afgcode_t_agriculture} 
    LEFT JOIN {t_agr_price} p ON p.{f_pkey_t_agr_price} = k.{f_pcat_t_agr_cat}, 
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_nutid,
            COALESCE(SUM(st_area(st_intersection(b.{f_geom_t_agriculture},{f_geom_Oversvømmelsesmodel, nutid}))),0)::NUMERIC(12,2) AS areal_oversvoem_nutid_m2,
            COALESCE(MIN({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
            COALESCE(MAX({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
            COALESCE(AVG({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS avg_vanddybde_nutid_cm
        FROM {Oversvømmelsesmodel, nutid} WHERE st_intersects(b.{f_geom_t_agriculture},{f_geom_Oversvømmelsesmodel, nutid}) AND {f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)}
    ) n,
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_fremtid,
            COALESCE(SUM(st_area(st_intersection(b.{f_geom_t_agriculture},{f_geom_Oversvømmelsesmodel, fremtid}))),0)::NUMERIC(12,2) AS areal_oversvoem_fremtid_m2,
            COALESCE(MIN({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS min_vanddybde_fremtid_cm,
            COALESCE(MAX({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS max_vanddybde_fremtid_cm,
            COALESCE(AVG({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS avg_vanddybde_fremtid_cm
        FROM {Oversvømmelsesmodel, fremtid} WHERE st_intersects(b.{f_geom_t_agriculture},{f_geom_Oversvømmelsesmodel, fremtid}) AND {f_depth_Oversvømmelsesmodel, fremtid} >= {Minimum vanddybde (meter)}
    ) f,
    LATERAL (
        SELECT
          ''{Medtag i risikoberegninger}'' AS risiko_beregning,
		  {Returperiode, antal år} AS retur_periode,
          ((
		      0.219058829 * CASE WHEN ''{Medtag i risikoberegninger}'' IN (''Skadebeløb'',''Skadebeløb og værditab'') THEN n.areal_oversvoem_nutid_m2 * p.{f_price_t_agr_price} /100.00 ELSE 0.0 END + 
              0.089925625   * CASE WHEN ''{Medtag i risikoberegninger}'' IN (''Skadebeløb'',''Skadebeløb og værditab'') THEN f.areal_oversvoem_fremtid_m2 * p.{f_price_t_agr_price} /100.00 ELSE 0.0 END
          )/{Returperiode, antal år})::NUMERIC(12,2) AS {f_risk_q_agriculture},
          '''' AS omraade
    ) r
	WHERE f.cnt_oversvoem_fremtid > 0 OR n.cnt_oversvoem_nutid > 0
', 'P', '', '', '', '', 'SQL template for agriculture model ', 8, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Perimeter cut-off (%)', 'Generelle modelværdier', '5.0', 'R', '0.0', '100.0', '1.0', '', 'Her angives minimum brøkdel af oversvømmet perimeter i procent, før bygning medtages i skadeberegning.', 17, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Skadeberegninger, Bygninger', 'Bygninger', '', 'T', '', '', '', 'q_build_peri', 'Skadeberegning for bygninger baseret på perimeter', 11, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_build_peri', 'q_build_peri', 'objectid', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_build_peri', 'q_build_peri', 'geom', 'T', '', '', '', '', 'Field name for geometry column', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_present_q_build_peri', 'q_build_peri', 'skadebeloeb_nutid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_future_q_build_peri', 'q_build_peri', 'skadebeloeb_fremtid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_cellar_present_q_build_peri', 'q_build_peri', 'skadebeloeb_kaelder_nutid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_cellar_future_q_build_peri', 'q_build_peri', 'skadebeloeb_kaelder_fremtid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_loss_present_q_build_peri', 'q_build_peri', 'vaerditab_nutid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_loss_future_q_build_peri', 'q_build_peri', 'vaerditab_fremtid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_risk_q_build_peri', 'q_build_peri', 'risiko_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_build_peri', 'Queries', '
SELECT
    b.*,
    d.{f_category_t_damage} AS skade_kategori,
    d.{f_type_t_damage} AS skade_type,
	''{Skadeberegning for kælder}'' AS kaelder_beregning,
    {Værditab, skaderamte bygninger (%)}::NUMERIC(12,2) as tab_procent,
    k.{f_sqmprice_t_sqmprice}::NUMERIC(12,2) as kvm_pris_kr,
    st_area(b.{f_geom_t_building})::NUMERIC(12,2) AS areal_byg_m2,
    st_perimeter(b.{f_geom_t_building})::NUMERIC(12,2) AS perimeter_byg_m,
    v.*,
    n.*,
    f.*,
    r.*
    FROM {t_building} b
    LEFT JOIN {t_build_usage} u on b.{f_usage_code_t_building} = u.{f_pkey_t_build_usage}
    LEFT JOIN {t_damage} d on u.{f_category_t_build_usage} = d.{f_category_t_damage} AND d.{f_type_t_damage} = ''{Skadetype}''   
    LEFT JOIN {t_sqmprice} k on (b.{f_muncode_t_building} = k.{f_muncode_t_sqmprice}),
    LATERAL (
        SELECT 
            ST_perimeter({f_geom_Oversvømmelsesmodel, nutid}) / 4.0 AS vp_side_laengde_m
        FROM {Oversvømmelsesmodel, nutid} LIMIT 1
    ) v, 
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_nutid,            
            100.0 * COUNT(*) * v.vp_side_laengde_m / ST_Perimeter(b.{f_geom_t_building}) AS oversvoem_peri_nutid_pct,            
            COALESCE(SUM(st_area(st_intersection(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, nutid}))),0)::NUMERIC(12,2) AS areal_oversvoem_nutid_m2,
            COALESCE(MIN({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
            COALESCE(MAX({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
            COALESCE(AVG({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS avg_vanddybde_nutid_cm,
            CASE WHEN COUNT(*) > 0 AND COUNT(*) * v.vp_side_laengde_m / ST_Perimeter(b.{f_geom_t_building}) >= {Perimeter cut-off (%)}/100.0 THEN d.b0 + st_area(b.{f_geom_t_building}) * (d.b1 * ln(GREATEST(MAX({f_depth_Oversvømmelsesmodel, nutid})*100.00, 1.0)) + d.b2) ELSE 0 END::NUMERIC(12,2) AS {f_damage_present_q_build_peri},
            CASE WHEN COUNT(*) > 0 AND COUNT(*) * v.vp_side_laengde_m / ST_Perimeter(b.{f_geom_t_building}) >= {Perimeter cut-off (%)}/100.0 AND ''{Skadeberegning for kælder}'' = ''Medtages'' THEN COALESCE(b.{f_cellar_area_t_building},0.0) * d.c0 ELSE 0 END::NUMERIC(12,2) as {f_damage_cellar_present_q_build_peri},
            CASE WHEN COUNT(*) > 0 THEN k.kvm_pris * st_area(b.{f_geom_t_building}) * {Værditab, skaderamte bygninger (%)}/100.0 ELSE 0 END::NUMERIC(12,2) as {f_loss_present_q_build_peri}             
        FROM {Oversvømmelsesmodel, nutid} WHERE st_intersects(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, nutid}) AND {f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)}
    ) n,
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_fremtid,
            100.0 * COUNT(*) * v.vp_side_laengde_m / ST_Perimeter(b.{f_geom_t_building}) AS oversvoem_peri_fremtid_pct,            
            COALESCE(SUM(st_area(st_intersection(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, fremtid}))),0)::NUMERIC(12,2) AS areal_oversvoem_fremtid_m2,
            COALESCE(MIN({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS min_vanddybde_fremtid_cm,
            COALESCE(MAX({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS max_vanddybde_fremtid_cm,
            COALESCE(AVG({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS avg_vanddybde_fremtid_cm,
            CASE WHEN COUNT (*) > 0 AND COUNT(*) * v.vp_side_laengde_m / ST_Perimeter(b.{f_geom_t_building}) >= {Perimeter cut-off (%)}/100.0 THEN d.b0 + st_area(b.{f_geom_t_building}) * (d.b1 * ln(GREATEST(MAX({f_depth_Oversvømmelsesmodel, fremtid})*100.00, 1.0)) + d.b2) ELSE 0 END::NUMERIC(12,2) AS {f_damage_future_q_build_peri},
            CASE WHEN COUNT (*) > 0 AND COUNT(*) * v.vp_side_laengde_m / ST_Perimeter(b.{f_geom_t_building}) >= {Perimeter cut-off (%)}/100.0 AND ''{Skadeberegning for kælder}'' = ''Medtages'' THEN COALESCE(b.{f_cellar_area_t_building},0.0) * d.c0 ELSE 0 END::NUMERIC(12,2) as {f_damage_cellar_future_q_build_peri},
            CASE WHEN COUNT (*) > 0 THEN k.kvm_pris * st_area(b.{f_geom_t_building}) * {Værditab, skaderamte bygninger (%)}/100.0 ELSE 0 END::NUMERIC(12,2) as {f_loss_future_q_build_peri}                
        FROM {Oversvømmelsesmodel, fremtid} WHERE st_intersects(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, fremtid}) AND {f_depth_Oversvømmelsesmodel, fremtid} >= {Minimum vanddybde (meter)}
    ) f,
    LATERAL (
        SELECT
          ''{Medtag i risikoberegninger}'' AS risiko_beregning,
		  {Returperiode, antal år} AS retur_periode,
          ((0.219058829 * CASE
          WHEN ''{Medtag i risikoberegninger}'' = ''Intet (0 kr.)'' THEN 0.0
          WHEN ''{Medtag i risikoberegninger}'' = ''Skadebeløb'' THEN n.{f_damage_present_q_build_peri} + n.{f_damage_cellar_present_q_build_peri}
          WHEN ''{Medtag i risikoberegninger}'' = ''Værditab'' THEN n.{f_loss_present_q_build_peri}
          WHEN ''{Medtag i risikoberegninger}'' = ''Skadebeløb og værditab'' THEN n.{f_damage_present_q_build_peri} + n.{f_damage_cellar_present_q_build_peri} + n.{f_loss_present_q_build_peri} 
          END + 
          0.089925625 * CASE
          WHEN ''{Medtag i risikoberegninger}'' = ''Intet (0 kr.)'' THEN 0.0
          WHEN ''{Medtag i risikoberegninger}'' = ''Skadebeløb'' THEN f.{f_damage_future_q_build_peri} + f.{f_damage_cellar_future_q_build_peri}
          WHEN ''{Medtag i risikoberegninger}'' = ''Værditab'' THEN f.{f_loss_future_q_build_peri}
          WHEN ''{Medtag i risikoberegninger}'' = ''Skadebeløb og værditab'' THEN f.{f_damage_future_q_build_peri} + f.{f_damage_cellar_future_q_build_peri} + f.{f_loss_future_q_build_peri} 
          END)/{Returperiode, antal år})::NUMERIC(12,2) AS {f_risk_q_build_peri},
          '''' AS omraade
    ) r
    WHERE f.cnt_oversvoem_fremtid > 0 OR n.cnt_oversvoem_nutid > 0', 'P', '', '', '', '', 'SQL template for buildings new model ', 8, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Humane omkostninger', 'Mennesker og helbred', '', 'T', '', '', '', 'q_human_health', 'Sæt hak såfremt der skal beregnes humane omkostninger', 10, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_human_health', 'q_human_health', 'rowid', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_human_health', 'q_human_health', 'geom', 'T', '', '', '', '', 'Field name for geometry column', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_present_q_human_health', 'q_human_health', 'skadebeloeb_nutid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_future_q_human_health', 'q_human_health', 'skadebeloeb_fremtid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_risk_q_human_health', 'q_human_health', 'risiko_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_human_health', 'Queries', '
SELECT 
    b.{f_pkey_t_building} as {f_pkey_q_human_health},
    b.{f_muncode_t_building} AS kom_kode,
    b.{f_usage_code_t_building} AS bbr_anv_kode,
    b.{f_usage_text_t_building} AS bbr_anv_tekst,
    st_area(b.{f_geom_t_building})::NUMERIC(12,2) AS areal_byg_m2,
    st_multi(st_force2d(b.{f_geom_t_building}))::Geometry(Multipolygon,25832) AS {f_geom_q_human_health},
    v.*,
    n.*,
    f.*,
    h.*,
    r.*
    FROM {t_building} b,
    LATERAL (
        SELECT 
            ST_perimeter({f_geom_Oversvømmelsesmodel, nutid}) / 4.0 AS vp_side_laengde_m FROM {Oversvømmelsesmodel, nutid} LIMIT 1
    ) v, 
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_nutid,
            100.0 * COUNT(*) * v.vp_side_laengde_m / ST_Perimeter(b.{f_geom_t_building}) AS oversvoem_peri_nutid_pct,            
            COALESCE((SUM(st_area(st_intersection(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, nutid})))),0)::NUMERIC(12,2) AS areal_oversvoem_nutid_m2,
            COALESCE((MIN({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
            COALESCE((MAX({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
            COALESCE((AVG({f_depth_Oversvømmelsesmodel, nutid}) * 100.00),0)::NUMERIC(12,2) AS avg_vanddybde_nutid_cm
        FROM {Oversvømmelsesmodel, nutid} WHERE st_intersects(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, nutid}) AND {f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)}
    ) n,
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_fremtid,
            100.0 * COUNT(*) * v.vp_side_laengde_m / ST_Perimeter(b.{f_geom_t_building}) AS oversvoem_peri_fremtid_pct,            
            COALESCE((SUM(st_area(st_intersection(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, fremtid})))),0)::NUMERIC(12,2) AS areal_oversvoem_fremtid_m2,
            COALESCE((MIN({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS min_vanddybde_fremtid_cm,
            COALESCE((MAX({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS max_vanddybde_fremtid_cm,
            COALESCE((AVG({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS avg_vanddybde_fremtid_cm
        FROM {Oversvømmelsesmodel, fremtid} WHERE st_intersects(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, fremtid}) AND {f_depth_Oversvømmelsesmodel, fremtid} >= {Minimum vanddybde (meter)}
    ) f,
    LATERAL (
        SELECT
            COUNT(*) AS mennesker_total,
            COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 0 AND 6) AS mennesker_0_6,
            COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 7 AND 17) AS mennesker_7_17,
            COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 18 AND 70) AS mennesker_18_70,
            COUNT(*) FILTER (WHERE {f_age_t_human_health} > 70) AS mennesker_71plus,
            CASE WHEN n.cnt_oversvoem_nutid > 0 AND n.oversvoem_peri_nutid_pct >= {Perimeter cut-off (%)} THEN COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 18 AND 70) * (138 * 301) ELSE 0 END::integer AS arbejdstid_nutid_kr,
            CASE WHEN n.cnt_oversvoem_nutid > 0 AND n.oversvoem_peri_nutid_pct >= {Perimeter cut-off (%)} THEN COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 18 AND 70) * (23  * 301) ELSE 0 END::integer AS rejsetid_nutid_kr,
            CASE WHEN n.cnt_oversvoem_nutid > 0 AND n.oversvoem_peri_nutid_pct >= {Perimeter cut-off (%)} THEN COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 18 AND 70) * (64  * 301) ELSE 0 END::integer AS sygetimer_nutid_kr, 
            CASE WHEN n.cnt_oversvoem_nutid > 0 AND n.oversvoem_peri_nutid_pct >= {Perimeter cut-off (%)} THEN COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 18 AND 70) * (26  * 301) ELSE 0 END::integer AS ferietimer_nutid_kr, 
            CASE WHEN f.cnt_oversvoem_fremtid > 0 AND f.oversvoem_peri_fremtid_pct >= {Perimeter cut-off (%)} THEN COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 18 AND 70) * (138 * 301) ELSE 0 END::integer AS arbejdstid_fremtid_kr,
            CASE WHEN f.cnt_oversvoem_fremtid > 0 AND f.oversvoem_peri_fremtid_pct >= {Perimeter cut-off (%)} THEN COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 18 AND 70) * (23  * 301) ELSE 0 END::integer AS rejsetid_fremtid_kr,
            CASE WHEN f.cnt_oversvoem_fremtid > 0 AND f.oversvoem_peri_fremtid_pct >= {Perimeter cut-off (%)} THEN COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 18 AND 70) * (64  * 301) ELSE 0 END::integer AS sygetimer_fremtid_kr, 
            CASE WHEN f.cnt_oversvoem_fremtid > 0 AND f.oversvoem_peri_fremtid_pct >= {Perimeter cut-off (%)} THEN COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 18 AND 70) * (26  * 301) ELSE 0 END::integer AS ferietimer_fremtid_kr 
        FROM {t_human_health} WHERE ST_CoveredBy({f_geom_t_human_health},b.{f_geom_t_building})
    ) h,
    LATERAL (
        SELECT
		    h.arbejdstid_nutid_kr + 
			h.rejsetid_nutid_kr + 
			h.sygetimer_nutid_kr + 
			h.ferietimer_nutid_kr AS {f_damage_present_q_human_health},
            h.arbejdstid_fremtid_kr + 
			h.rejsetid_fremtid_kr + 
			h.sygetimer_fremtid_kr + 
			h.ferietimer_fremtid_kr AS {f_damage_future_q_human_health},
            ''{Medtag i risikoberegninger}'' AS risiko_beregning,
		    {Returperiode, antal år} AS retur_periode,
            ((
			    0.219058829 * CASE WHEN ''{Medtag i risikoberegninger}'' IN (''Skadebeløb'',''Skadebeløb og værditab'') THEN 
			        h.arbejdstid_nutid_kr + 
					h.rejsetid_nutid_kr + 
					h.sygetimer_nutid_kr + 
					h.ferietimer_nutid_kr ELSE 0 END
				 +
                0.089925625 * CASE WHEN ''{Medtag i risikoberegninger}'' IN (''Skadebeløb'',''Skadebeløb og værditab'') THEN
                    h.arbejdstid_fremtid_kr + 
					h.rejsetid_fremtid_kr + 
					h.sygetimer_fremtid_kr + 
					h.ferietimer_fremtid_kr ELSE 0 END
				)/{Returperiode, antal år})::NUMERIC(12,2) AS {f_risk_q_human_health},
            '''' AS omraade
    ) r
    WHERE (f.cnt_oversvoem_fremtid > 0 OR n.cnt_oversvoem_nutid > 0) AND h.mennesker_total > 0
', 'P', '', '', '', '', 'SQL template for human health new model ', 8, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Turisme, Kort', 'Turisme', '', 'T', '', '', '', 'q_tourism_spatial', 'Sæt hak såfremt der skal beregnes økonomiske tab for overnatningssteder som anvendes til turistformål. De berørte bygninger vises geografisk på et kort.  ', 10, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_tourism_spatial', 'q_tourism_spatial', 'fid', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_tourism_spatial', 'q_tourism_spatial', 'geom', 'T', '', '', '', '', 'Field name for geometry column', 10, ' ');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_present_q_tourism_spatial', 'q_tourism_spatial', 'skadebeloeb_nutid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_damage_future_q_tourism_spatial', 'q_tourism_spatial', 'skadebeloeb_fremtid_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_risk_q_tourism_spatial', 'q_tourism_spatial', 'risiko_kr', 'T', '', '', '', '', '', 1, 'T');
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_tourism_spatial', 'Queries', '
SELECT
    b.{f_pkey_t_building} as {f_pkey_q_tourism_spatial},
    b.{f_muncode_t_building} AS kom_kode,
    b.{f_usage_code_t_building} AS bbr_anv_kode,
    t.bbr_anv_tekst AS bbr_anv_tekst,
    t.kapacitet AS kapacitet,
    t.omkostning AS omkostninger,
    {Antal tabte døgn} AS tabte_dage,
    {Antal tabte døgn} * t.kapacitet AS tabte_overnatninger,
    st_force2d(b.{f_geom_t_building}) AS {f_geom_q_tourism_spatial},
	v.*,
    n.*,
    f.*,
    r.*
    FROM {t_building} b
    INNER JOIN {t_tourism} t  ON t.{f_pkey_t_tourism} = b.{f_usage_code_t_building},  
    LATERAL (
        SELECT ST_perimeter({f_geom_Oversvømmelsesmodel, nutid}) / 4.0 AS vp_side_laengde_m FROM {Oversvømmelsesmodel, nutid} LIMIT 1
    ) v, 
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_nutid,
            100.0 * COUNT(*) * v.vp_side_laengde_m / ST_Perimeter(b.{f_geom_t_building}) AS oversvoem_peri_nutid_pct,            
            COALESCE(SUM(st_area(st_intersection(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, nutid}))),0)::NUMERIC(12,2) AS areal_oversvoem_nutid_m2,
            COALESCE(MIN({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
            COALESCE(MAX({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
            COALESCE(AVG({f_depth_Oversvømmelsesmodel, nutid}) * 100.00,0)::NUMERIC(12,2) AS avg_vanddybde_nutid_cm,
            CASE WHEN COUNT (*) > 0 AND 100.0 * COUNT(*) * v.vp_side_laengde_m / ST_Perimeter(b.{f_geom_t_building}) >= {Perimeter cut-off (%)} THEN {Antal tabte døgn} * t.omkostning * t.kapacitet ELSE 0 END::NUMERIC(12,2) AS {f_damage_present_q_tourism_spatial}
        FROM {Oversvømmelsesmodel, nutid} WHERE st_intersects(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, nutid}) AND {f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)}
    ) n,
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_fremtid,
            100.0 * COUNT(*) * v.vp_side_laengde_m / ST_Perimeter(b.{f_geom_t_building}) AS oversvoem_peri_fremtid_pct,            
            COALESCE(SUM(st_area(st_intersection(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, fremtid}))),0)::NUMERIC(12,2) AS areal_oversvoem_fremtid_m2,
            COALESCE(MIN({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS min_vanddybde_fremtid_cm,
            COALESCE(MAX({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS max_vanddybde_fremtid_cm,
            COALESCE(AVG({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00,0)::NUMERIC(12,2) AS avg_vanddybde_fremtid_cm,
            CASE WHEN COUNT (*) > 0 AND 100.0 * COUNT(*) * v.vp_side_laengde_m / ST_Perimeter(b.{f_geom_t_building}) >= {Perimeter cut-off (%)} THEN {Antal tabte døgn} * t.omkostning * t.kapacitet ELSE 0 END::NUMERIC(12,2) AS {f_damage_future_q_tourism_spatial}
        FROM {Oversvømmelsesmodel, fremtid} WHERE st_intersects(b.{f_geom_t_building},{f_geom_Oversvømmelsesmodel, fremtid}) AND {f_depth_Oversvømmelsesmodel, fremtid} >= {Minimum vanddybde (meter)}
    ) f,
    LATERAL (
        SELECT
          ''{Medtag i risikoberegninger}'' AS risiko_beregning,
		  {Returperiode, antal år} AS retur_periode,
          ((
		      0.219058829 * CASE WHEN ''{Medtag i risikoberegninger}'' IN (''Skadebeløb'',''Skadebeløb og værditab'') THEN n.{f_damage_present_q_tourism_spatial} ELSE 0.0 END + 
              0.089925625   * CASE WHEN ''{Medtag i risikoberegninger}'' IN (''Skadebeløb'',''Skadebeløb og værditab'') THEN f.{f_damage_future_q_tourism_spatial} ELSE 0.0 END
          )/{Returperiode, antal år})::NUMERIC(12,2) AS {f_risk_q_tourism_spatial},
          '''' AS omraade
    ) r
	WHERE f.cnt_oversvoem_fremtid > 0 OR n.cnt_oversvoem_nutid > 0
', 'P', '', '', '', '', 'SQL template for buildings new model ', 8, ' ');



-- Setup primary key and indexes
ALTER TABLE ONLY parametre ADD CONSTRAINT parametre_pkey PRIMARY KEY (name);
CREATE INDEX parametre_parent_idx ON parametre USING btree (parent);

-- Setup result tables and sequence

SET search_path = fdc_results, public;

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
    CONSTRAINT batches_pkey PRIMARY KEY (bid)
);

CREATE TABLE IF NOT EXISTS used_models
(
    mid bigint NOT NULL DEFAULT nextval('fdc_results.id_numbers'),
    bid bigint NOT NULL,
    name character varying COLLATE pg_catalog."default" NOT NULL,
    no_rows INT,
	no_secs DOUBLE PRECISION,
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