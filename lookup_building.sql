SET search_path = fdc_lookup, public;

ALTER TABLE IF EXISTS skadefunktioner DROP CONSTRAINT IF EXISTS skadefunktioner_pkey;
ALTER TABLE IF EXISTS kvm_pris DROP CONSTRAINT IF EXISTS kvm_pris_pkey;
ALTER TABLE IF EXISTS bbr_anvendelse DROP CONSTRAINT IF EXISTS bbr_anvendelse_pkey;

CREATE TABLE IF NOT EXISTS skadefunktioner (
    skade_type character varying NOT NULL,
    skade_kategori character varying NOT NULL,
    b0 double precision NOT NULL,
    b1 double precision NOT NULL,
    b2 double precision NOT NULL,
    c0 double precision NOT NULL
);
TRUNCATE skadefunktioner;

INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Stormflod', 'Helårsbeboelse', 0, 1167.86, -571.21, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Stormflod', 'Sommerhus', 0, 1681.71, -2128.87, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Stormflod', 'Garage mm.', 30000, 0, 0, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Stormflod', 'Anneks', 30000, 0, 0, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Stormflod', 'Erhverv', 0, 1387.94, -881.8, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Stormflod', 'Kultur', 0, 1387.94, -881.8, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Stormflod', 'Forsyning', 0, 1387.94, -881.8, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Stormflod', 'Offentlig', 0, 1387.94, -881.8, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Stormflod', 'Ingen data', 0, 0, 2000, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Stormflod', 'Andet', 0, 0, 2000, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Skybrud', 'Helårsbeboelse', 0, 0, 1257, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Skybrud', 'Sommerhus', 0, 0, 1249, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Skybrud', 'Garage mm.', 30000, 0, 0, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Skybrud', 'Anneks', 30000, 0, 0, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Skybrud', 'Erhverv', 0, 0, 1407, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Skybrud', 'Kultur', 0, 0, 1407, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Skybrud', 'Forsyning', 0, 0, 1407, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Skybrud', 'Offentlig', 0, 0, 1407, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Skybrud', 'Ingen data', 0, 0, 1000, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Skybrud', 'Andet', 0, 0, 1000, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Vandløb', 'Helårsbeboelse', 0, 389.29, -190.4, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Vandløb', 'Sommerhus', 0, 560.57, -709.62, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Vandløb', 'Garage mm.', 30000, 0, 0, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Vandløb', 'Anneks', 30000, 0, 0, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Vandløb', 'Erhverv', 0, 462.65, -293.93, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Vandløb', 'Kultur', 0, 462.65, -293.93, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Vandløb', 'Forsyning', 0, 462.65, -293.93, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Vandløb', 'Offentlig', 0, 462.65, -293.93, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Vandløb', 'Ingen data', 0, 0, 1000, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Vandløb', 'Andet', 0, 0, 1000, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Stormflod', 'Erhverv_lav', 0, 346.98, -220.45, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Skybrud', 'Erhverv_lav', 0, 0, 351.63, 578);
INSERT INTO skadefunktioner (skade_type, skade_kategori, b0, b1, b2, c0) VALUES ('Vandløb', 'Erhverv_lav', 0, 115.66, -73.48, 578);


CREATE TABLE IF NOT EXISTS kvm_pris (
    kom_kode integer NOT NULL,
    kom_navn character varying,
    kvm_pris integer
);

TRUNCATE kvm_pris;

INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (101, 'København', 45176);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (147, 'Frederiksberg', 59438);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (151, 'Ballerup', 28690);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (153, 'Brøndby', 26420);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (155, 'Dragør', 35188);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (157, 'Gentofte', 49302);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (159, 'Gladsaxe', 33252);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (161, 'Glostrup', 27695);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (163, 'Herlev', 29974);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (165, 'Albertslund', 23424);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (167, 'Hvidovre', 31036);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (169, 'Høje-Taastrup', 23976);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (173, 'Lyngby-Taarbæk', 39551);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (175, 'Rødovre', 31634);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (183, 'Ishøj', 23212);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (185, 'Tårnby', 33092);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (187, 'Vallensbæk', 26305);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (190, 'Furesø', 29563);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (201, 'Allerød', 27341);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (210, 'Fredensborg', 23627);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (217, 'Helsingør', 25324);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (219, 'Hillerød', 24838);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (223, 'Hørsholm', 35647);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (230, 'Rudersdal', 35674);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (240, 'Egedal', 25282);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (250, 'Frederikssund', 20082);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (253, 'Greve', 27563);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (259, 'Køge', 24013);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (260, 'Halsnæs', 16758);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (265, 'Roskilde', 27134);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (269, 'Solrød', 27536);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (270, 'Gribskov', 19180);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (306, 'Odsherred', 11309);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (316, 'Holbæk', 18149);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (320, 'Faxe', 13763);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (326, 'Kalundborg', 9007);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (329, 'Ringsted', 15186);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (330, 'Slagelse', 11445);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (336, 'Stevns', 13202);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (340, 'Sorø', 12856);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (350, 'Lejre', 18255);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (360, 'Lolland', 4596);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (370, 'Næstved', 12866);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (376, 'Guldborgsund', 9381);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (390, 'Vordingborg', 11425);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (400, 'Bornholm', 12527);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (410, 'Middelfart', 13999);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (411, 'Christiansø', NULL);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (420, 'Assens', 7879);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (430, 'Faaborg-Midtfyn', 10176);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (440, 'Kerteminde', 11366);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (450, 'Nyborg', 11595);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (461, 'Odense', 20248);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (479, 'Svendborg', 14294);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (480, 'Nordfyns', 12339);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (482, 'Langeland', 9558);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (492, 'Ærø', 6836);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (510, 'Haderslev', 10428);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (530, 'Billund', 9325);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (540, 'Sønderborg', 10989);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (550, 'Tønder', 8291);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (561, 'Esbjerg', 14513);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (563, 'Fanø', 13030);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (573, 'Varde', 10444);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (575, 'Vejen', 8031);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (580, 'Aabenraa', 9667);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (607, 'Fredericia', 13168);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (615, 'Horsens', 14417);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (621, 'Kolding', 14294);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (630, 'Vejle', 16023);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (657, 'Herning', 12833);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (661, 'Holstebro', 11470);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (665, 'Lemvig', 8211);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (671, 'Struer', 7435);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (706, 'Syddjurs', 16043);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (707, 'Norddjurs', 8376);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (710, 'Favrskov', 13207);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (727, 'Odder', 14663);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (730, 'Randers', 10454);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (740, 'Silkeborg', 16612);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (741, 'Samsø', 8242);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (746, 'Skanderborg', 19055);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (751, 'Aarhus', 30649);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (756, 'Ikast-Brande', 11393);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (760, 'Ringkøbing-Skjern', 11188);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (766, 'Hedensted', 12912);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (773, 'Morsø', 5353);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (779, 'Skive', 7593);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (787, 'Thisted', 9780);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (791, 'Viborg', 11738);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (810, 'Brønderslev', 7673);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (813, 'Frederikshavn', 14226);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (820, 'Vesthimmerlands', 6987);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (825, 'Læsø', NULL);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (840, 'Rebild', 10752);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (846, 'Mariagerfjord', 9581);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (849, 'Jammerbugt', 11058);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (851, 'Aalborg', 17421);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (860, 'Hjørring', 10664);
INSERT INTO kvm_pris (kom_kode, kom_navn, kvm_pris) VALUES (999, 'Danmark', 13897);


CREATE TABLE IF NOT EXISTS bbr_anvendelse (
    bbr_anv_kode integer NOT NULL,
    bbr_anv_tekst character varying,
    skade_kategori character varying
);

TRUNCATE bbr_anvendelse;

INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (-9999, 'No Data', 'Ingen data');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (110, 'Stuehus til landbrugsejendom', 'Helårsbeboelse');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (120, 'Fritliggende enfamilieshus (parcelhus)', 'Helårsbeboelse');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (121, 'Sammenbygget enfamiliehus', 'Helårsbeboelse');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (122, 'Fritliggende enfamiliehus i tæt-lav bebyggelse', 'Helårsbeboelse');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (130, '(UDFASES) Række-, kæde-, eller dobbelthus (lodret adskillelse mellem enhederne).', 'Helårsbeboelse');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (131, 'Række- og kædehus', 'Helårsbeboelse');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (132, 'Dobbelthus', 'Helårsbeboelse');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (140, 'Etagebolig-bygning, flerfamilehus eller to-familiehus', 'Helårsbeboelse');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (150, 'Kollegium', 'Helårsbeboelse');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (160, 'Boligbygning til døgninstitution', 'Helårsbeboelse');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (185, 'Anneks i tilknytning til helårsbolig.', 'Helårsbeboelse');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (190, 'Anden bygning til helårsbeboelse', 'Helårsbeboelse');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (210, '(UDFASES) Bygning til erhvervsmæssig produktion vedrørende landbrug, gartneri, råstofudvinding o. lign', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (217, 'Maskinhus, garage mv.', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (219, 'Anden bygning til landbrug mv.', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (220, '(UDFASES) Bygning til erhvervsmæssig produktion vedrørende industri, håndværk m.v. (fabrik, værksted o.lign.)', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (221, 'Bygning til industri med integreret produktionsapparat', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (222, 'Bygning til industri uden integreret produktionsapparat', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (223, 'Værksted', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (229, 'Anden bygning til produktion', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (230, '(UDFASES) El-, gas-, vand- eller varmeværk, forbrændingsanstalt m.v.', 'Forsyning');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (231, 'Bygning til energiproduktion', 'Forsyning');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (232, 'Bygning til forsyning- og energidistribution', 'Forsyning');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (233, 'Bygning til vandforsyning', 'Forsyning');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (234, 'Bygning til håndtering af affald og spildevand', 'Forsyning');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (239, 'Anden bygning til energiproduktion og -distribution', 'Forsyning');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (290, '(UDFASES) Anden bygning til landbrug, industri etc.', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (311, 'Bygning til jernbane- og busdrift', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (312, 'Bygning til luftfart', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (315, 'Havneanlæg', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (320, '(UDFASES) Bygning til kontor, handel, lager, herunder offentlig administration', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (321, 'Bygning til kontor', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (322, 'Bygning til detailhandel', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (324, 'Butikscenter', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (325, 'Tankstation', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (329, 'Anden bygning til kontor, handel og lager', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (330, '(UDFASES) Bygning til hotel, restaurant, vaskeri, frisør og anden servicevirksomhed', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (331, 'Hotel, kro eller konferencecenter med overnatning', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (332, 'Bed & breakfast mv.', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (333, 'Restaurant, café og konferencecenter uden overnatning', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (334, 'Privat servicevirksomhed som frisør, vaskeri, netcafé mv.', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (339, 'Anden bygning til serviceerhverv', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (390, '(UDFASES) Anden bygning til transport, handel etc', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (410, '(UDFASES) Bygning til biograf, teater, erhvervsmæssig udstilling, bibliotek, museum, kirke o. lign.', 'Kultur');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (411, 'Biograf, teater, koncertsted mv.', 'Kultur');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (412, 'Museum', 'Kultur');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (413, 'Bibliotek', 'Kultur');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (414, 'Kirke eller anden bygning til trosudøvelse for statsanerkendte trossamfund', 'Kultur');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (415, 'Forsamlingshus', 'Kultur');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (416, 'Forlystelsespark', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (419, 'Anden bygning til kulturelle formål', 'Kultur');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (420, '(UDFASES) Bygning til undervisning og forskning (skole, gymnasium, forskningslabratorium o.lign.).', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (421, 'Grundskole', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (422, 'Universitet', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (429, 'Anden bygning til undervisning og forskning', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (430, '(UDFASES) Bygning til hospital, sygehjem, fødeklinik o. lign.', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (431, 'Hospital og sygehus', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (432, 'Hospice, behandlingshjem mv.', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (433, 'Sundhedscenter, lægehus, fødeklinik mv.', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (439, 'Anden bygning til sundhedsformål', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (440, '(UDFASES) Bygning til daginstitution', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (441, 'Daginstitution', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (442, 'Servicefunktion på døgninstitution', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (443, 'Kaserne', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (444, 'Fængsel, arresthus mv.', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (449, 'Anden bygning til institutionsformål', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (490, '(UDFASES) Bygning til anden institution, herunder kaserne, fængsel o. lign.', 'Offentlig');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (510, 'Bygninger til sommerhus', 'Sommerhus');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (520, '(UDFASES) Bygning til feriekoloni, vandrehjem o.lign. bortset fra sommerhus', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (521, 'Feriecenter, center til campingplads mv.', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (522, 'Bygning med ferielejligheder til erhvervsmæssig udlejning', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (523, 'Bygning med ferielejligheder til eget brug', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (532, 'Svømmehal', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (529, 'Anden bygning til ferieformål', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (530, '(UDFASES) Bygning i forbindelse med idrætsudøvelse (klubhus, idrætshal, svømmehal o. lign.)', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (531, 'Klubhus i forbindelse med fritid og idræt', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (533, 'Idrætshal', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (539, 'Anden bygning til idrætformål', 'Erhverv');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (540, 'Kolonihavehus', 'Sommerhus');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (585, 'Anneks i tilknytning til fritids- og sommerhus', 'Anneks');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (590, 'Anden bygning til fritidsformål', 'Anneks');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (910, 'Garage (med plads til et eller to køretøjer)', 'Garage mm.');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (920, 'Carport', 'Garage mm.');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (930, 'Udhus', 'Garage mm.');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (940, 'Drivhus', 'Andet');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (950, 'Fritliggende overdækning', 'Andet');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (960, 'Fritliggende udestue', 'Andet');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (970, 'Tiloversbleven landbrugsbygning', 'Andet');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (990, 'Faldefærdig bygning', 'Andet');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (999, 'Ukendt bygning', 'Andet');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (211, 'Stald til svin', 'Erhverv_lav');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (212, 'Stald til kvæg, får mv.', 'Erhverv_lav');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (213, 'Stald til fjerkræ', 'Erhverv_lav');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (214, 'Minkhal', 'Erhverv_lav');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (215, 'Væksthus', 'Erhverv_lav');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (216, 'Lade til foder, afgrøder mv.', 'Erhverv_lav');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (218, 'Lade til halm, hø mv.', 'Erhverv_lav');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (310, '(UDFASES) Transport- og garageanlæg (fragtmandshal, lufthavnsbygning, banegårdsbygning, parkeringshus).', 'Erhverv_lav');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (313, 'Bygning til parkering- og transportanlæg', 'Erhverv_lav');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (314, 'Bygning til parkering af flere end to køretøjer i tilknytning til boliger', 'Erhverv_lav');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (319, 'Andet transportanlæg', 'Erhverv_lav');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (323, 'Bygning til lager', 'Erhverv_lav');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (534, 'Tribune i forbindelse med stadion', 'Erhverv_lav');
INSERT INTO bbr_anvendelse (bbr_anv_kode, bbr_anv_tekst, skade_kategori) VALUES (535, 'Rideskole', 'Erhverv_lav');

ALTER TABLE ONLY bbr_anvendelse ADD CONSTRAINT bbr_anvendelse_pkey PRIMARY KEY (bbr_anv_kode);
ALTER TABLE ONLY kvm_pris ADD CONSTRAINT kvm_pris_pkey PRIMARY KEY (kom_kode);
ALTER TABLE ONLY skadefunktioner ADD CONSTRAINT skadefunktioner_pkey PRIMARY KEY (skade_type, skade_kategori);



