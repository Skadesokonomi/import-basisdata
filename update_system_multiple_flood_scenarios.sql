SET search_path = fdc_admin, public;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_building', 'Queries', '
SELECT /* Multiple flood scenarios version */
    b.*,
    d.{f_category_t_damage} AS skade_kategori,
    d.{f_type_t_damage} AS skade_type,
	''{Skadeberegning for kælder}'' AS kaelder_beregning,
    {Værditab, skaderamte bygninger (%)}::NUMERIC(12,2) as tab_procent,
    k.{f_sqmprice_t_sqmprice}::NUMERIC(12,2) as kvm_pris_kr,
    st_area(b.{f_geom_t_building})::NUMERIC(12,2) AS areal_byg_m2,
    n.*,
/*
    f.*,
    r.*
*/
    '''' AS omraade
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
    ) n
/* ,
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
*/
    WHERE /* f.cnt_oversvoem_fremtid > 0 OR */ n.cnt_oversvoem_nutid > 0', 'P', '', '', '', '', 'SQL template for buildings new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_recreative', 'Queries', '
SELECT /* Multiple flood scenarios version */
    b.*,
    {Antal dage med oversvømmelse} AS periode_dage, 
    st_area(b.{f_geom_t_recreative})::NUMERIC(12,2) AS areal_m2,
    n.*,
/*
    f.*,
*/
    h.*,
/*
    r.*
*/
    '''' AS omraade
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
/*
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_fremtid,
            COALESCE((SUM(st_area(st_intersection(b.{f_geom_t_recreative},{f_geom_Oversvømmelsesmodel, fremtid})))),0)::NUMERIC(12,2) AS areal_oversvoem_fremtid_m2,
            COALESCE((MIN({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS min_vanddybde_fremtid_cm,
            COALESCE((MAX({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS max_vanddybde_fremtid_cm,
            COALESCE((AVG({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS avg_vanddybde_fremtid_cm
        FROM {Oversvømmelsesmodel, fremtid} WHERE st_intersects(b.{f_geom_t_recreative},{f_geom_Oversvømmelsesmodel, fremtid}) AND {f_depth_Oversvømmelsesmodel, fremtid} >= {Minimum vanddybde (meter)}
    ) f,
*/
    LATERAL (
        SELECT
            (100.0 * n.areal_oversvoem_nutid_m2/st_area(b.{f_geom_t_recreative}))::NUMERIC(12,2) AS oversvoem_nutid_pct,
/*
            (100.0 * f.areal_oversvoem_fremtid_m2/st_area(b.{f_geom_t_recreative}))::NUMERIC(12,2) AS oversvoem_fremtid_pct,
*/
            (({Antal dage med oversvømmelse}/365.0) * (n.areal_oversvoem_nutid_m2/st_area(b.{f_geom_t_recreative})) * b.valuationk)::NUMERIC(12,2)  AS {f_damage_present_q_recreative}
/* ,
            (({Antal dage med oversvømmelse}/365.0) * (f.areal_oversvoem_fremtid_m2/st_area(b.{f_geom_t_recreative})) * b.valuationk)::NUMERIC(12,2)  AS {f_damage_future_q_recreative}		    
*/
    ) h
/* ,
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
*/
    WHERE /* f.cnt_oversvoem_fremtid > 0 OR */ n.cnt_oversvoem_nutid > 0', 'P', '', '', '', '', 'SQL template for recreative new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_road_traffic', 'Queries', '
SELECT /* Multiple flood scenarios version */
    b.*,
    n.*,
--    f.*,
    {Oversvømmelsesperiode (timer)} AS blokering_timer,
    0.3 AS vanddybde_bloker_m,
    0.075 AS vanddybde_min_m,
	{Renovationspris pr meter vej (DKK)} AS pris_renovation_kr_m,
    h.*,
	i.*,
--    r.*
    '''' AS omraade
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
/*
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_fremtid,
            COALESCE((SUM(st_length(st_intersection(b.{f_geom_t_road_traffic},{f_geom_Oversvømmelsesmodel, fremtid})))),0)::NUMERIC(12,2) AS laengde_oversvoem_fremtid_m,
            COALESCE((MIN({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS min_vanddybde_fremtid_cm,
            COALESCE((MAX({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS max_vanddybde_fremtid_cm,
            COALESCE((AVG({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS avg_vanddybde_fremtid_cm
        FROM {Oversvømmelsesmodel, fremtid} WHERE st_intersects(b.{f_geom_t_road_traffic},{f_geom_Oversvømmelsesmodel, fremtid}) AND {f_depth_Oversvømmelsesmodel, fremtid} >= 0.075
    ) f,
*/
    LATERAL (
        SELECT
            CASE WHEN n.avg_vanddybde_nutid_cm >= 30.0 THEN 0.0 ELSE 0.0009 * (n.avg_vanddybde_nutid_cm*10.0)^2.0 - 0.5529 * n.avg_vanddybde_nutid_cm*10.0 + 86.9448 END::NUMERIC(12,2) AS hastighed_red_nutid_km_time,
--            CASE WHEN f.avg_vanddybde_fremtid_cm >= 30.0 THEN 0.0 ELSE 0.0009 * (f.avg_vanddybde_fremtid_cm*10.0)^2.0 - 0.5529 * f.avg_vanddybde_fremtid_cm*10.0 + 86.9448 END::NUMERIC(12,2) AS hastighed_red_fremtid_km_time,
            n.laengde_oversvoem_nutid_m * {Renovationspris pr meter vej (DKK)} AS skade_renovation_nutid_kr --,
--            f.laengde_oversvoem_fremtid_m * {Renovationspris pr meter vej (DKK)} AS skade_renovation_fremtid_kr
    ) h,
    LATERAL (
        SELECT
            CASE WHEN h.hastighed_red_nutid_km_time > 50.0 THEN 0.0 ELSE (68.8 - 1.376 * h.hastighed_red_nutid_km_time) * ({Oversvømmelsesperiode (timer)} / 24.0) * n.laengde_org_m * (b.{f_number_cars_t_road_traffic}/6200.00)*2.0 END::NUMERIC(12,2) AS skade_transport_nutid_kr --,
--            CASE WHEN h.hastighed_red_fremtid_km_time > 50.0 THEN 0.0 ELSE (68.8 - 1.376 * h.hastighed_red_fremtid_km_time) * ({Oversvømmelsesperiode (timer)} / 24.0) * n.laengde_org_m * (b.{f_number_cars_t_road_traffic}/6200.00)*2.0 END::NUMERIC(12,2) AS skade_transport_fremtid_kr
    ) i
/* ,
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
*/
    WHERE /* f.cnt_oversvoem_fremtid > 0 OR */ n.cnt_oversvoem_nutid > 0', 'P', '', '', '', '', 'SQL template for road traffic new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_surrounding_loss', 'Queries', '
WITH 
/*
    of AS (SELECT b.{f_pkey_t_building}, b.{f_geom_t_building} FROM {t_building} b WHERE EXISTS ( SELECT 1 FROM {Oversvømmelsesmodel, fremtid} f WHERE st_intersects (f.{f_geom_Oversvømmelsesmodel, fremtid}, b.{f_geom_t_building}) AND  f.{f_depth_Oversvømmelsesmodel, fremtid} >= {Minimum vanddybde (meter)})),
*/
    op AS (SELECT b.{f_pkey_t_building}, b.{f_geom_t_building} FROM {t_building} b WHERE EXISTS ( SELECT 1 FROM {Oversvømmelsesmodel, nutid} f WHERE st_intersects (f.{f_geom_Oversvømmelsesmodel, nutid}, b.{f_geom_t_building}) AND  f.{f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)}))

SELECT /* Multiple flood scenarios version */
    x.*,
    st_area(x.{f_geom_t_building})::NUMERIC(12,2) AS areal_byg_m2,
    k.{f_sqmprice_t_sqmprice}::NUMERIC(12,2) AS kvm_pris_kr,
    ({Værditab, skaderamte bygninger (%)}*{Faktor for værditab})::NUMERIC(12,2) AS tab_procent,
/*
    CASE WHEN y.{f_pkey_t_building} IS NULL THEN 0.0 ELSE k.{f_sqmprice_t_sqmprice} * st_area(x.{f_geom_t_building}) * {Værditab, skaderamte bygninger (%)}*{Faktor for værditab} / 100.0 END::NUMERIC(12,2) AS {f_loss_future_q_surrounding_loss},
*/
    CASE WHEN z.{f_pkey_t_building} IS NULL THEN 0.0 ELSE k.{f_sqmprice_t_sqmprice} * st_area(x.{f_geom_t_building}) * {Værditab, skaderamte bygninger (%)}*{Faktor for værditab} / 100.0 END::NUMERIC(12,2) AS {f_loss_present_q_surrounding_loss},
/* 
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
*/
    '''' AS omraade
FROM {t_building} x 
/*
LEFT JOIN (SELECT DISTINCT c.{f_pkey_t_building} FROM {t_building} c, of WHERE c.{f_pkey_t_building} NOT IN (SELECT {f_pkey_t_building} from of) and st_dwithin(of.{f_geom_t_building},c.{f_geom_t_building},300.)) y ON x.{f_pkey_t_building} = y.{f_pkey_t_building} 
*/
LEFT JOIN (SELECT DISTINCT c.{f_pkey_t_building} FROM {t_building} c, op WHERE c.{f_pkey_t_building} NOT IN (SELECT {f_pkey_t_building} from op) and st_dwithin(op.{f_geom_t_building},c.{f_geom_t_building},300.)) z ON x.{f_pkey_t_building} = z.{f_pkey_t_building} 
LEFT JOIN {t_sqmprice} k ON k.kom_kode = x.komkode 
WHERE /* y.{f_pkey_t_building} IS NOT NULL */ OR z.{f_pkey_t_building} IS NOT NULL', 'P', '', '', '', '', 'SQL template for surrounding loss - new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_bioscore_spatial', 'Queries', '
SELECT /* Multiple flood scenarios version */
    c.*,
	st_area(c.{f_geom_t_bioscore})::NUMERIC(12,2) AS areal_m2,
    n.*,
/*
    f.*,
    {Returperiode, antal år} AS retur_periode,
*/
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
    ) n --,
/*
    LATERAL (
        SELECT
            COUNT (*) AS cnt_oversvoem_fremtid,
            COALESCE((SUM(st_area(st_intersection(c.{f_geom_t_bioscore},{f_geom_Oversvømmelsesmodel, fremtid})))),0)::NUMERIC(12,2) AS areal_oversvoem_fremtid_m2,
            COALESCE((MIN({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS min_vanddybde_fremtid_cm,
            COALESCE((MAX({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS max_vanddybde_fremtid_cm,
            COALESCE((AVG({f_depth_Oversvømmelsesmodel, fremtid}) * 100.00),0)::NUMERIC(12,2) AS avg_vanddybde_fremtid_cm
        FROM {Oversvømmelsesmodel, fremtid} WHERE {f_depth_Oversvømmelsesmodel, fremtid} >= {Minimum vanddybde (meter)} AND st_intersects(c.{f_geom_t_bioscore},{f_geom_Oversvømmelsesmodel, fremtid})
    ) f
*/
WHERE n.cnt_oversvoem_nutid > 0 /* OR f.cnt_oversvoem_fremtid > 0 */ ', 'P', '', '', '', '', 'SQL template for bioscore spatial - new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_comp_build', 'Queries', '
SELECT /* Multiple flood scenarios version */
    row_number() OVER () as {f_pkey_q_comp_build},
    c.*,
    b.{f_pkey_t_building} AS byg_id,
    b.{f_muncode_t_building} AS kom_kode,
    b.{f_usage_code_t_building} AS bbr_anv_kode,
    b.{f_usage_text_t_building} AS bbr_anv_tekst,
    n.*,
/*
    f.*,
    {Returperiode, antal år} AS retur_periode,
*/
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
    ) n --,
/*
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
*/
WHERE n.cnt_oversvoem_nutid > 0 /* OR f.cnt_oversvoem_fremtid > 0 */', 'P', '', '', '', '', 'SQL template for human health new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_infrastructure', 'Queries', '
SELECT /* Multiple flood scenarios version */ DISTINCT ON (o.{f_pkey_t_infrastructure}) 
    o.*,
    n.*,
/*
    f.*,
    {Returperiode, antal år} AS retur_periode,
*/
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
    ) n
/* ,
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
*/
    WHERE /* f.cnt_oversvoem_fremtid > 0 OR */ n.cnt_oversvoem_nutid > 0', 'P', '', '', '', '', 'SQL template for infrastructure new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_publicservice', 'Queries', '
SELECT /* Multiple flood scenarios version */ DISTINCT ON (o.{f_pkey_t_publicservice}) 
    o.*,
    n.*,
/*
    f.*,
	{Returperiode, antal år} AS retur_periode,
*/
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
    ) n 
/*,
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
*/
    WHERE /* f.cnt_oversvoem_fremtid > 0 OR */ n.cnt_oversvoem_nutid > 0', 'P', '', '', '', '', 'SQL template for public service new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;


INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_build_peri', 'Queries', '
SELECT /* Multiple flood scenarios version */
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
/* 
    f.*,
    r.*
*/
    '''' AS omraade
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
    ) n
/* ,
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
*/
    WHERE /* f.cnt_oversvoem_fremtid > 0 OR */ n.cnt_oversvoem_nutid > 0', 'P', '', '', '', '', 'SQL template for buildings new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_human_health', 'Queries', '
SELECT /* Multiple flood scenarios version */
    b.{f_pkey_t_building} as {f_pkey_q_human_health},
    b.{f_muncode_t_building} AS kom_kode,
    b.{f_usage_code_t_building} AS bbr_anv_kode,
    b.{f_usage_text_t_building} AS bbr_anv_tekst,
    st_area(b.{f_geom_t_building})::NUMERIC(12,2) AS areal_byg_m2,
    st_multi(st_force2d(b.{f_geom_t_building}))::Geometry(Multipolygon,25832) AS {f_geom_q_human_health},
    v.*,
    n.*,
/*
    f.*,
*/
    h.*,
/*
    r.*
*/
    '''' AS omraade
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
/*
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
*/
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
            CASE WHEN n.cnt_oversvoem_nutid > 0 AND n.oversvoem_peri_nutid_pct >= {Perimeter cut-off (%)} THEN COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 18 AND 70) * (26  * 301) ELSE 0 END::integer AS ferietimer_nutid_kr
/* ,
            CASE WHEN f.cnt_oversvoem_fremtid > 0 AND f.oversvoem_peri_fremtid_pct >= {Perimeter cut-off (%)} THEN COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 18 AND 70) * (138 * 301) ELSE 0 END::integer AS arbejdstid_fremtid_kr,
            CASE WHEN f.cnt_oversvoem_fremtid > 0 AND f.oversvoem_peri_fremtid_pct >= {Perimeter cut-off (%)} THEN COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 18 AND 70) * (23  * 301) ELSE 0 END::integer AS rejsetid_fremtid_kr,
            CASE WHEN f.cnt_oversvoem_fremtid > 0 AND f.oversvoem_peri_fremtid_pct >= {Perimeter cut-off (%)} THEN COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 18 AND 70) * (64  * 301) ELSE 0 END::integer AS sygetimer_fremtid_kr, 
            CASE WHEN f.cnt_oversvoem_fremtid > 0 AND f.oversvoem_peri_fremtid_pct >= {Perimeter cut-off (%)} THEN COUNT(*) FILTER (WHERE {f_age_t_human_health} BETWEEN 18 AND 70) * (26  * 301) ELSE 0 END::integer AS ferietimer_fremtid_kr 
*/
        FROM {t_human_health} WHERE ST_CoveredBy({f_geom_t_human_health},b.{f_geom_t_building})
    ) h
/* ,
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
*/
    WHERE (/* f.cnt_oversvoem_fremtid > 0 OR */ n.cnt_oversvoem_nutid > 0) AND h.mennesker_total > 0', 'P', '', '', '', '', 'SQL template for human health new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_tourism_spatial', 'Queries', '
SELECT /* Multiple flood scenarios version */
    b.{f_pkey_t_building} as {f_pkey_q_tourism_spatial},
    b.{f_muncode_t_building} AS kom_kode,
    b.{f_usage_code_t_building} AS bbr_anv_kode,
    t.bbr_anv_tekst AS bbr_anv_tekst,
    t.kapacitet AS kapacitet,
    t.omkostning AS omkostninger,
    {Antal tabte døgn} AS tabte_dage,
    {Antal tabte døgn} * t.kapacitet AS tabte_overnatninger,
    st_multi(st_force2d(b.{f_geom_t_building}))::Geometry(Multipolygon,25832) AS {f_geom_q_tourism_spatial},
	v.*,
    n.*,
/*
    f.*,
    r.*
*/
    '''' AS omraade
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
    ) n
/*,
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
*/
	WHERE /* f.cnt_oversvoem_fremtid > 0 OR */ n.cnt_oversvoem_nutid > 0', 'P', '', '', '', '', 'SQL template for buildings new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_agriculture', 'Queries', '
SELECT /* Multiple flood scenarios version */
    b.*,
    k.afgroedegruppe,
    k.afgroedekategori,
    p.*,
    n.*,
    COALESCE(areal_oversvoem_nutid_m2 * p.{f_price_t_agr_price} /100.00,0.0)::NUMERIC(12,2) AS {f_damage_present_q_agriculture},
/*
    f.*,
    COALESCE(areal_oversvoem_fremtid_m2 * p.{f_price_t_agr_price} /100.00,0.0)::NUMERIC(12,2) AS {f_damage_future_q_agriculture},
    r.*
*/
    '''' AS omraade
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
    ) n
/* ,
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
		      0.219058829 * CASE WHEN ''{Medtag i risikoberegninger}'' IN (''Skadebeløb'',''Skadebeløb og værditab'') THEN COALESCE(n.areal_oversvoem_nutid_m2 * p.{f_price_t_agr_price} /100.00,0.0) ELSE 0.0 END + 
              0.089925625   * CASE WHEN ''{Medtag i risikoberegninger}'' IN (''Skadebeløb'',''Skadebeløb og værditab'') THEN COALESCE(f.areal_oversvoem_fremtid_m2 * p.{f_price_t_agr_price} /100.00,0.0) ELSE 0.0 END
          )/{Returperiode, antal år})::NUMERIC(12,2) AS {f_risk_q_agriculture},
          '''' AS omraade
    ) r
*/
	WHERE /* f.cnt_oversvoem_fremtid > 0 OR */ n.cnt_oversvoem_nutid > 0', 'P', '', '', '', '', 'SQL template for agriculture model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

SET search_path = fdc_admin, public;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_build_peri_new', 'Queries', '
WITH b1 AS (
    SELECT 
        bg.{f_pkey_t_building},
        st_length(st_intersection(ov.{f_geom_Oversvømmelsesmodel, nutid},ST_ExteriorRing((ST_Dump(bg.{f_geom_t_building})).geom))) as perimeter_overlap_m,
        ST_Area(ST_intersection(bg.{f_geom_t_building}, ov.{f_geom_Oversvømmelsesmodel, nutid})) AS areal_overlap_m2,
        ov.{f_depth_Oversvømmelsesmodel, nutid}
	FROM {t_building} bg
	JOIN {Oversvømmelsesmodel, nutid} ov ON st_intersects(bg.{f_geom_t_building},ov.{f_geom_Oversvømmelsesmodel, nutid}) AND ov.{f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)} 
),
b2 AS (
    SELECT 
        {f_pkey_t_building},
        SUM (perimeter_overlap_m)::NUMERIC(12,2) AS perimeter_overlap_m,
        SUM (areal_overlap_m2)::NUMERIC(12,2) AS areal_oversvoem_nutid_m2,
        (100.0 * (MIN({f_depth_Oversvømmelsesmodel, nutid})))::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
        (100.0 * (MAX({f_depth_Oversvømmelsesmodel, nutid})))::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
        (100.0 * (AVG({f_depth_Oversvømmelsesmodel, nutid})))::NUMERIC(12,2) AS avg_vanddybde_nutid_cm,
        COUNT(*) AS cnt_oversvoem_nutid
	FROM b1
    GROUP BY {f_pkey_t_building}
)
SELECT /* Multiple flood scenarios version */
    b.*,
    d.{f_category_t_damage} AS skade_kategori,
    d.{f_type_t_damage} AS skade_type,
	''{Skadeberegning for kælder}'' AS kaelder_beregning,
    {Værditab, skaderamte bygninger (%)}::NUMERIC(12,2) as tab_procent,
    k.{f_sqmprice_t_sqmprice}::NUMERIC(12,2) as kvm_pris_kr,
    st_area(b.{f_geom_t_building})::NUMERIC(12,2) AS areal_byg_m2,
    st_perimeter(b.{f_geom_t_building})::NUMERIC(12,2) AS perimeter_byg_m,
    b2.cnt_oversvoem_nutid,            
    (100.0 * b2.perimeter_overlap_m / ST_Perimeter(b.{f_geom_t_building}))::NUMERIC(12,2) AS oversvoem_peri_nutid_pct,            
    b2.areal_oversvoem_nutid_m2::NUMERIC(12,2),
    b2.min_vanddybde_nutid_cm::NUMERIC(12,2),
    b2.max_vanddybde_nutid_cm::NUMERIC(12,2),
    b2.avg_vanddybde_nutid_cm::NUMERIC(12,2),
    d.b0 + st_area(b.{f_geom_t_building}) * (d.b1 * ln(GREATEST(b2.max_vanddybde_nutid_cm, 1.0)) + d.b2)::NUMERIC(12,2) AS {f_damage_present_q_build_peri},
    CASE WHEN ''{Skadeberegning for kælder}'' = ''Medtages'' THEN COALESCE(b.{f_cellar_area_t_building},0.0) * d.c0 ELSE 0 END::NUMERIC(12,2) AS {f_damage_cellar_present_q_build_peri},
    (k.kvm_pris * st_area(b.{f_geom_t_building}) * {Værditab, skaderamte bygninger (%)}/100.0)::NUMERIC(12,2) as {f_loss_present_q_build_peri},             
    '''' AS omraade
    FROM b2
    LEFT JOIN {t_building} b on b.{f_pkey_t_building} = b2.{f_pkey_t_building}
    LEFT JOIN {t_build_usage} u on b.{f_usage_code_t_building} = u.{f_pkey_t_build_usage}
    LEFT JOIN {t_damage} d on u.{f_category_t_build_usage} = d.{f_category_t_damage} AND d.{f_type_t_damage} = ''{Skadetype}''   
    LEFT JOIN {t_sqmprice} k on (b.{f_muncode_t_building} = k.{f_muncode_t_sqmprice})
    WHERE b2.perimeter_overlap_m / ST_Perimeter(b.{f_geom_t_building}) >= {Perimeter cut-off (%)}/100.0', 'P', '', '', '', '', 'SQL template for buildings new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_build_peri_buffer', 'Queries', '
WITH b1 AS (
    SELECT 
        bg.{f_pkey_t_building},
        st_length(st_intersection(ov.{f_geom_Oversvømmelsesmodel, nutid},ST_ExteriorRing((ST_Dump(bg.{f_geom_t_building})).geom))) as perimeter_overlap_m,
        ST_Area(ST_intersection(bg.{f_geom_t_building}, ov.{f_geom_Oversvømmelsesmodel, nutid})) AS areal_overlap_m2,
        ov.{f_depth_Oversvømmelsesmodel, nutid}
	FROM {t_building} bg
	JOIN {Oversvømmelsesmodel, nutid} ov ON st_intersects(st_buffer(bg.{f_geom_t_building},{Bygnings buffer (meter)}),ov.{f_geom_Oversvømmelsesmodel, nutid}) AND ov.{f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)} 
),
b2 AS (
    SELECT 
        {f_pkey_t_building},
        SUM (perimeter_overlap_m)::NUMERIC(12,2) AS perimeter_overlap_m,
        SUM (areal_overlap_m2)::NUMERIC(12,2) AS areal_oversvoem_nutid_m2,
        (100.0 * (MIN({f_depth_Oversvømmelsesmodel, nutid})))::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
        (100.0 * (MAX({f_depth_Oversvømmelsesmodel, nutid})))::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
        (100.0 * (AVG({f_depth_Oversvømmelsesmodel, nutid})))::NUMERIC(12,2) AS avg_vanddybde_nutid_cm,
        COUNT(*) AS cnt_oversvoem_nutid
	FROM b1
    GROUP BY {f_pkey_t_building}
)
SELECT /* Multiple flood scenarios version */
    b.*,
    d.{f_category_t_damage} AS skade_kategori,
    d.{f_type_t_damage} AS skade_type,
	''{Skadeberegning for kælder}'' AS kaelder_beregning,
    {Værditab, skaderamte bygninger (%)}::NUMERIC(12,2) as tab_procent,
    k.{f_sqmprice_t_sqmprice}::NUMERIC(12,2) as kvm_pris_kr,
    st_area(b.{f_geom_t_building})::NUMERIC(12,2) AS areal_byg_m2,
    st_perimeter(b.{f_geom_t_building})::NUMERIC(12,2) AS perimeter_byg_m,
    b2.cnt_oversvoem_nutid,            
    (100.0 * b2.perimeter_overlap_m / ST_Perimeter(b.{f_geom_t_building}))::NUMERIC(12,2) AS oversvoem_peri_nutid_pct,            
    b2.areal_oversvoem_nutid_m2::NUMERIC(12,2),
    b2.min_vanddybde_nutid_cm::NUMERIC(12,2),
    b2.max_vanddybde_nutid_cm::NUMERIC(12,2),
    b2.avg_vanddybde_nutid_cm::NUMERIC(12,2),
    d.b0 + st_area(b.{f_geom_t_building}) * (d.b1 * ln(GREATEST(b2.max_vanddybde_nutid_cm, 1.0)) + d.b2)::NUMERIC(12,2) AS {f_damage_present_q_build_peri},
    CASE WHEN ''{Skadeberegning for kælder}'' = ''Medtages'' THEN COALESCE(b.{f_cellar_area_t_building},0.0) * d.c0 ELSE 0 END::NUMERIC(12,2) AS {f_damage_cellar_present_q_build_peri},
    (k.kvm_pris * st_area(b.{f_geom_t_building}) * {Værditab, skaderamte bygninger (%)}/100.0)::NUMERIC(12,2) as {f_loss_present_q_build_peri},             
    '''' AS omraade
    FROM b2
    LEFT JOIN {t_building} b on b.{f_pkey_t_building} = b2.{f_pkey_t_building}
    LEFT JOIN {t_build_usage} u on b.{f_usage_code_t_building} = u.{f_pkey_t_build_usage}
    LEFT JOIN {t_damage} d on u.{f_category_t_build_usage} = d.{f_category_t_damage} AND d.{f_type_t_damage} = ''{Skadetype}''   
    LEFT JOIN {t_sqmprice} k on (b.{f_muncode_t_building} = k.{f_muncode_t_sqmprice})
    WHERE b2.perimeter_overlap_m / ST_Perimeter(b.{f_geom_t_building}) >= {Perimeter cut-off (%)}/100.0', 'P', '', '', '', '', 'SQL template for buildings new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_human_health_new', 'Queries', '
WITH b1 AS (
    SELECT 
        bg.{f_pkey_t_building},
        st_length(st_intersection(ov.{f_geom_Oversvømmelsesmodel, nutid},ST_ExteriorRing((ST_Dump(bg.{f_geom_t_building})).geom))) as perimeter_overlap_m,
        ST_Area(ST_intersection(bg.{f_geom_t_building}, ov.{f_geom_Oversvømmelsesmodel, nutid})) AS areal_overlap_m2,
        ov.{f_depth_Oversvømmelsesmodel, nutid}
	FROM {t_building} bg
	JOIN {Oversvømmelsesmodel, nutid} ov ON st_intersects(bg.{f_geom_t_building},ov.{f_geom_Oversvømmelsesmodel, nutid}) AND ov.{f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)} 
),
b2 AS (
    SELECT 
        {f_pkey_t_building},
        SUM (perimeter_overlap_m)::NUMERIC(12,2) AS perimeter_overlap_m,
        SUM (areal_overlap_m2)::NUMERIC(12,2) AS areal_oversvoem_nutid_m2,
        (100.0 * (MIN({f_depth_Oversvømmelsesmodel, nutid})))::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
        (100.0 * (MAX({f_depth_Oversvømmelsesmodel, nutid})))::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
        (100.0 * (AVG({f_depth_Oversvømmelsesmodel, nutid})))::NUMERIC(12,2) AS avg_vanddybde_nutid_cm,
        COUNT(*) AS cnt_oversvoem_nutid
	FROM b1
    GROUP BY {f_pkey_t_building}
),
b3 AS (
    SELECT 
        b2.*,
        COUNT(*) AS mennesker_total,
        COUNT(*) FILTER (WHERE h.{f_age_t_human_health} BETWEEN 0 AND 6) AS mennesker_0_6,
        COUNT(*) FILTER (WHERE h.{f_age_t_human_health} BETWEEN 7 AND 17) AS mennesker_7_17,
        COUNT(*) FILTER (WHERE h.{f_age_t_human_health} BETWEEN 18 AND 70) AS mennesker_18_70,
        COUNT(*) FILTER (WHERE h.{f_age_t_human_health} > 70) AS mennesker_71plus,
        COUNT(*) FILTER (WHERE h.{f_age_t_human_health} BETWEEN 18 AND 70) * (138 * 301)::integer AS arbejdstid_nutid_kr,
        COUNT(*) FILTER (WHERE h.{f_age_t_human_health} BETWEEN 18 AND 70) * (23  * 301)::integer AS rejsetid_nutid_kr,
        COUNT(*) FILTER (WHERE h.{f_age_t_human_health} BETWEEN 18 AND 70) * (64  * 301)::integer AS sygetimer_nutid_kr, 
        COUNT(*) FILTER (WHERE h.{f_age_t_human_health} BETWEEN 18 AND 70) * (26  * 301)::integer AS ferietimer_nutid_kr
	FROM b2
	JOIN {t_human_health} h ON ST_CoveredBy(h.{f_geom_t_human_health},b2.{f_geom_t_building}) 
    GROUP BY b2.{f_pkey_t_building})
SELECT /* Multiple flood scenarios version */
    b3.*,
	b.{f_pkey_t_building} as {f_pkey_q_human_health},
    b.{f_muncode_t_building} AS kom_kode,
    b.{f_usage_code_t_building} AS bbr_anv_kode,
    b.{f_usage_text_t_building} AS bbr_anv_tekst,
    st_area(b.{f_geom_t_building})::NUMERIC(12,2) AS areal_byg_m2,
    st_multi(st_force2d(b.{f_geom_t_building}))::Geometry(Multipolygon,25832) AS {f_geom_q_human_health},
    '''' AS omraade
    FROM {t_building} b
	JOIN b3 ON b3.{f_pkey_t_building} = b.{f_pkey_t_building}
	WHERE b3.perimeter_overlap_m / ST_Perimeter(b.{f_geom_t_building}) >= {Perimeter cut-off (%)}/100.0', 'P', '', '', '', '', 'SQL template for human health new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;


INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('q_tourism_spatial_new', 'Queries', '
WITH b1 AS (
    SELECT 
        bg.{f_pkey_t_building},
        st_length(st_intersection(ov.{f_geom_Oversvømmelsesmodel, nutid},ST_ExteriorRing((ST_Dump(bg.{f_geom_t_building})).geom))) as perimeter_overlap_m,
        ST_Area(ST_intersection(bg.{f_geom_t_building}, ov.{f_geom_Oversvømmelsesmodel, nutid})) AS areal_overlap_m2,
        ov.{f_depth_Oversvømmelsesmodel, nutid}
	FROM {t_building} bg
	JOIN {Oversvømmelsesmodel, nutid} ov ON st_intersects(bg.{f_geom_t_building},ov.{f_geom_Oversvømmelsesmodel, nutid}) AND ov.{f_depth_Oversvømmelsesmodel, nutid} >= {Minimum vanddybde (meter)} 
),
b2 AS (
    SELECT 
        {f_pkey_t_building},
        SUM (perimeter_overlap_m)::NUMERIC(12,2) AS perimeter_overlap_m,
        SUM (areal_overlap_m2)::NUMERIC(12,2) AS areal_oversvoem_nutid_m2,
        (100.0 * (MIN({f_depth_Oversvømmelsesmodel, nutid})))::NUMERIC(12,2) AS min_vanddybde_nutid_cm,
        (100.0 * (MAX({f_depth_Oversvømmelsesmodel, nutid})))::NUMERIC(12,2) AS max_vanddybde_nutid_cm,
        (100.0 * (AVG({f_depth_Oversvømmelsesmodel, nutid})))::NUMERIC(12,2) AS avg_vanddybde_nutid_cm,
        COUNT(*) AS cnt_oversvoem_nutid
	FROM b1
    GROUP BY {f_pkey_t_building}
)
SELECT /* Multiple flood scenarios version */
    b2.*,
    b.{f_muncode_t_building} AS kom_kode,
    b.{f_usage_code_t_building} AS bbr_anv_kode,
    t.bbr_anv_tekst AS bbr_anv_tekst,
    t.kapacitet AS kapacitet,
    t.omkostning AS omkostninger,
    {Antal tabte døgn} AS tabte_dage,
    {Antal tabte døgn} * t.kapacitet AS tabte_overnatninger,
    st_multi(st_force2d(b.{f_geom_t_building}))::Geometry(Multipolygon,25832) AS {f_geom_q_tourism_spatial},
    '''' AS omraade
    FROM {t_building} b
	JOIN b2 ON b2.{f_pkey_t_building} = b.{f_pkey_t_building}
	JOIN {t_tourism} t  ON t.{f_pkey_t_tourism} = b.{f_usage_code_t_building}  
	WHERE b3.perimeter_overlap_m / ST_Perimeter(b.{f_geom_t_building}) >= {Perimeter cut-off (%)}/100.0    
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
    ) n
/*,
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
*/
	WHERE /* f.cnt_oversvoem_fremtid > 0 OR */ n.cnt_oversvoem_nutid > 0',

	'P', '', '', '', '', 'SQL template for tourism new model ', 8, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Skadeberegninger, Bygninger ny,', 'Bygninger', '', 'T', '', '', '', 'q_build_peri_new', 'Skadeberegning for bygninger baseret på perimeter', 11, 'T')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_build_peri_new', 'q_build_peri_new', 'fid', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_build_peri_new', 'q_build_peri_new', 'geom', 'T', '', '', '', '', 'Field name for geometry column', 10, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_build_peri_buffer', 'q_build_peri_buffer', 'fid', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_build_peri_buffer', 'q_build_peri_buffer', 'geom', 'T', '', '', '', '', 'Field name for geometry column', 10, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Bygnings buffer (meter)', 'Generelle modelværdier', '1.0', 'R', '0.0', '100.0', '1.0', '', 'Her angives størresle i meter af bygnings bufferzone', 17, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Skadeberegninger, Bygninger buffer,', 'Bygninger', '', 'T', '', '', '', 'q_build_peri_buffer', 'Skadeberegning for bygninger baseret på perimeter', 11, 'T')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('Humane omkostninger ny', 'Mennesker og helbred', '', 'T', '', '', '', 'q_human_health_new', 'Sæt hak såfremt der skal beregnes humane omkostninger', 10, 'T')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_pkey_q_human_health_new', 'q_human_health_new', 'fid', 'T', '', '', '', '', 'Name of primary keyfield for query', 10, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO parametre (name, parent, value, type, minval, maxval, lookupvalues, "default", explanation, sort, checkable) VALUES ('f_geom_q_human_health_new', 'q_human_health_new', 'geom', 'T', '', '', '', '', 'Field name for geometry column', 10, ' ')
ON CONFLICT (name) DO UPDATE SET value = EXCLUDED.value;
