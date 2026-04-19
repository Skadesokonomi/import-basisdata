DROP TABLE IF EXISTS tgv_data.tgv_temp;
CREATE TABLE tgv_data.tgv_temp AS 
(                WITH c1 AS (
                    SELECT
                        tc.project_id,
                        tc.cell_no,
                        c.spring,
                        c.summer,
                        c.autumn,
                        c.winter,
                        2019::integer AS mstart,
						30::integer AS mperiod,
						'Initial data'::character varying AS model_id,
                        generate_series('2048-01-01'::date,'2053-12-31'::date,'1 day'::interval) AS date_stamp
                    FROM tgv_data.tgv_cells tc 
					LEFT JOIN tgv_data.tgv_cells c ON c.cell_no = tc.cell_no AND c.project_id = tc.project_id 
                    WHERE tc.project_id = 'Markby'
                ),
                c2 AS (
                    SELECT 
                        c1.project_id,
						c1.model_id,
                        c1.cell_no, 
                        c1.date_stamp,
						c1.mperiod,
                        c1.spring,
                        c1.summer,
                        c1.autumn,
                        c1.winter,
                        (EXTRACT(YEAR FROM c1.date_stamp) - c1.mstart)::integer AS afst,
                        DIV(EXTRACT(YEAR FROM c1.date_stamp) - c1.mstart,c1.mperiod) AS mpant,
                        EXTRACT(YEAR  FROM c1.date_stamp)::integer AS dsyear,
                        EXTRACT(MONTH FROM c1.date_stamp)::integer AS dsmonth,
                        EXTRACT(DAY   FROM c1.date_stamp)::integer AS dsday
                    FROM c1			
			    ),
                c3 AS ( 
                    SELECT
                        c2.project_id,
                        c2.cell_no,
                        c2.model_id,
                        c2.date_stamp,
						(c2.mpant*2)::integer AS mpant2,
                        (CASE 
                             WHEN dsmonth IN (12,1,2) THEN c2.winter
                             WHEN dsmonth IN (3,4,5) THEN c2.spring 
                             WHEN dsmonth IN (6,7,8) THEN c2.summer
                             ELSE c2.autumn 
                        END)::real AS correction,
						c2.date_stamp - FORMAT('%s YEARS',((c2.mpant+1)*c2.mperiod)::integer)::interval AS pdate_stamp
                FROM c2
                )
				SELECT * FROM c3);
ALTER TABLE tgv_data.tgv_temp ADD CONSTRAINT tgv_temp_pkey PRIMARY KEY (project_id, cell_no, model_id, date_stamp);
ALTER TABLE tgv_data.tgv_temp
    ADD CONSTRAINT "VVV" FOREIGN KEY (project_id, model_id, cell_no, pdate_stamp) REFERENCES tgv_data.tgv_cell_values (project_id, model_id, cell_no, date_stamp) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;

CREATE INDEX "fki_fourkey" ON tgv_data.tgv_temp(project_id, model_id, cell_no, pdate_stamp);	
/*
MERGE INTO tgv_data.tgv_cell_values cv
USING tgv_data.tgv_temp c3 ON 
    cv.project_id = c3.project_id AND
    cv.model_id = c3.model_id AND
    cv.cell_no = c3.cell_no AND 
    cv.date_stamp = c3.pdate_stamp
WHEN MATCHED THEN UPDATE SET depth = EXCLUDED.depth
WHEN NOT MATCHED THEN
    INSERT (project_id,model_id,cell_no,date_stamp,depth)
    VALUES (u.name, u.price, u.stock, u.status)

                    DELETE FROM tgv_data.tgv_cell_values cv USING tgv_data.tgv_temp c3 WHERE 
                        cv.project_id = c3.project_id AND
                        cv.model_id = c3.model_id AND
                        cv.cell_no = c3.cell_no AND 
                        cv.date_stamp = c3.date_stamp;
*/					

                    INSERT INTO tgv_data.tgv_cell_values 
                    SELECT 
                        c3.project_id,
                        c3.model_id,
                        c3.cell_no,
                        c3.date_stamp,
						(cv.depth + correction*c3.mpant2)::real AS depth 
                    FROM tgv_data.tgv_temp c3 JOIN tgv_data.tgv_cell_values cv ON
                        cv.project_id = c3.project_id AND
                        cv.model_id = c3.model_id AND
                        cv.cell_no = c3.cell_no AND 
                        cv.date_stamp = c3.pdate_stamp
					ON CONFLICT ON CONSTRAINT tgv_cell_values_pkey DO 
                        UPDATE SET depth = EXCLUDED.depth;
