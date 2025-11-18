WITH 
  one AS (
    SELECT * FROM fdc_admin.parametre WHERE name LIKE 't_flood_%' AND POSITION('{schemaname}' in value) > 0 AND POSITION('{tablename}' in value) > 0 
    UNION ( SELECT * FROM fdc_admin.parametre WHERE name LIKE 't_flood_%' AND COALESCE(value,'') = '' ORDER BY name ASC LIMIT 1) ORDER BY value DESC LIMIT 1), 

  two AS (
    UPDATE fdc_admin.parametre SET value = '"{schemaname}"."{tablename}"' WHERE name in (SELECT name FROM one)), 

  three AS (
    UPDATE fdc_admin.parametre SET value = '"fid"' WHERE name in (SELECT 'f_pkey_'||name FROM one)), 

  four AS (
    UPDATE fdc_admin.parametre SET value = '"vanddybde_m"' WHERE name in (SELECT 'f_depth_'||name FROM one)) 

UPDATE fdc_admin.parametre SET value = '"geom"' WHERE name in (SELECT 'f_geom_'||name FROM one);
