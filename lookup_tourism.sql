SET search_path = fdc_lookup, public;

ALTER TABLE IF EXISTS turisme DROP CONSTRAINT IF EXISTS turisme_pkey;

CREATE TABLE IF NOT EXISTS turisme (
    bbr_anv_kode integer NOT NULL,
    bbr_anv_tekst character varying(255) NOT NULL,
    kapacitet integer NOT NULL,
    omkostning integer NOT NULL
);

TRUNCATE turisme;

INSERT INTO turisme (bbr_anv_kode, bbr_anv_tekst, kapacitet, omkostning) VALUES (520, '(UDFASES) Bygning til feriekoloni, vandrehjem o.lign. bortset fra sommerhus', 10, 2362);
INSERT INTO turisme (bbr_anv_kode, bbr_anv_tekst, kapacitet, omkostning) VALUES (331, 'Hotel, kro eller konferencecenter med overnatning', 50, 2362);
INSERT INTO turisme (bbr_anv_kode, bbr_anv_tekst, kapacitet, omkostning) VALUES (332, 'Bed & breakfast mv.', 8, 2362);
INSERT INTO turisme (bbr_anv_kode, bbr_anv_tekst, kapacitet, omkostning) VALUES (510, 'Bygninger til sommerhus', 6, 2362);
INSERT INTO turisme (bbr_anv_kode, bbr_anv_tekst, kapacitet, omkostning) VALUES (521, 'Feriecenter, center til campingplads mv.', 100, 2362);
INSERT INTO turisme (bbr_anv_kode, bbr_anv_tekst, kapacitet, omkostning) VALUES (522, 'Bygning med ferielejligheder til erhvervsmæssig udlejning', 50, 2362);

ALTER TABLE ONLY turisme ADD CONSTRAINT turisme_pkey PRIMARY KEY (bbr_anv_kode);

