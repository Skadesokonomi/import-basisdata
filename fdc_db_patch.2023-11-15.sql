/*
-----------------------------------------------------------------------
--   Patch 2023-11-15: Ver 2 opdateringer
-----------------------------------------------------------------------

     search_path skal værdisættes, således at navnet på administrations schema er første parameter. 
     Hvis der ikke er ændret på standard navn for administrationsskema "fdc_admin"
     skal der ikke rettes i linjen

*/
SET search_path = fdc_admin, public;
--                *********

-- NIX PILLE VED RESTEN....................................................................................................

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable)
    VALUES ('f_geom_t_recreative', 't_recreative', 'geom', 'T', '', '', '', '', '', 1, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'geom';        

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_geom_t_building', 't_building', 'geom', 'T', '', '', '', '', 'Field name for geometry field in building table', 10, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'geom';      

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_geom_t_bioscore', 't_bioscore', 'geom', 'T', '', '', '', '', '', 10, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'geom';         

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_geom_t_infrastructure', 't_infrastructure', 'geom', 'T', '', '', '', '', '', 1, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'geom';             

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_geom_t_human_health', 't_human_health', 'geom', 'T', '', '', '', '', 'Field name for geometry field in Human health table ', 10, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'geom';     

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_geom_t_publicservice', 't_publicservice', 'geom', 'T', '', '', '', '', '', 1, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'geom';       

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_geom_t_road_traffic', 't_road_traffic', 'geom', 'T', '', '', '', '', '', 10, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'geom';       

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_geom_t_agriculture', 't_agriculture', 'geom', 'F', '', '', '', '', 'Field name for geometry column', 10, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'geom';   

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_geom_t_flood_50', 't_flood_50', 'geom', 'F', '', '', '', '', 'Field name for geometry field in flood table', 10, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'geom';    

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_pkey_t_recreative', 't_recreative', 'fid', 'T', '', '', '', '', '', 10, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'fid';        

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_pkey_t_building', 't_building', 'fid', 'T', '', '', '', '', '', 10, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'fid';      

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_pkey_t_bioscore', 't_bioscore', 'fid', 'T', '', '', '', '', '', 10, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'fid';         

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_pkey_t_infrastructure', 't_infrastructure', 'fid', 'T', '', '', '', '', '', 1, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'fid';             

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_pkey_t_human_health', 't_human_health', 'fid', 'T', '', '', '', '', 'Field name for keyfield in Human health table ', 10, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'fid';     

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_pkey_t_publicservice', 't_publicservice', 'fid', 'T', '', '', '', '', '', 1, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'fid';       

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_pkey_t_road_traffic', 't_road_traffic', 'fid', 'T', '', '', '', '', '', 10, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'fid';

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_pkey_t_agriculture', 't_agriculture', 'fid', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'fid';          

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) 
    VALUES ('f_pkey_t_flood_50', 't_flood_50', 'fid', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ')
    ON CONFLICT (name) DO UPDATE SET value = 'fid';    

UPDATE parametre set value = 'bbr_anv_kode' WHERE name = 'f_usage_code_t_building';