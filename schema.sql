CREATE TABLE geoname (
    id              INTEGER,
    name            TEXT,
    ascii_name      TEXT,
    alternate_names TEXT,
    latitude        FLOAT,
    longitude       FLOAT,
    feature_class   CHAR(1),
    feature_code    CHAR(10),
    country         CHAR(2),
    cc2             TEXT,
    admin1          TEXT,
    admin2          TEXT,
    admin3          TEXT,
    admin4          TEXT,
    population      BIGINT,
    elevation       INTEGER,
    dem             INTEGER,
    timezone        TEXT,
    modified_on     DATE
);

CREATE TABLE hierarchy (
    parent_id       INTEGER,
    child_id        INTEGER,
    type            TEXT
);

CREATE TABLE alternate_names (
    id                INTEGER,
    geoname_id        INTEGER,
    iso_language      TEXT,
    alternate_name    TEXT,
    is_preferred_name BOOLEAN,
    is_short_name     BOOLEAN,
    is_colloquial     BOOLEAN,
    is_historic       BOOLEAN,
    usage_from        TEXT,
    usage_to          TEXT
);

CREATE TABLE country_info (
    iso_alpha2           CHAR(2),
    iso_alpha3           CHAR(3),
    iso_numeric          INTEGER,
    fips_code            TEXT,
    country              TEXT,
    capital              TEXT,
    area                 DOUBLE PRECISION, -- square km
    population           INTEGER,
    continent            CHAR(2),
    tld                  TEXT,
    currency_code        CHAR(3),
    currency_name        TEXT,
    phone                TEXT,
    postal               TEXT,
    postal_regex         TEXT,
    languages            TEXT,
    geoname_id           INTEGER,
    neighbours           TEXT,
    equivalent_fips_code TEXT
);

CREATE TABLE iso_language_codes(
    iso_639_3     CHAR(3),
    iso_639_2     TEXT,
    iso_639_1     CHAR(2),
    language_name TEXT
);

CREATE TABLE admin1_codes (
    code       CHAR(20),
    name       TEXT,
    name_ascii TEXT,
    geoname_id INTEGER
);

CREATE TABLE admin2_codes (
    code       CHAR(30),
    name       TEXT,
    name_ascii TEXT,
    geoname_id INTEGER
    -- dst_offset NUMERIC(3,1),
    -- raw_offset NUMERIC(3,1)
);

CREATE TABLE admin5_codes (
    geoname_id INTEGER,
    admin5     TEXT
);

CREATE TABLE feature_codes (
    code        CHAR(7),
    name        TEXT,
    description TEXT
);

CREATE TABLE time_zones (
    country_code CHAR(2),
    id           TEXT,
    gmt_offset   NUMERIC(3,1),
    dst_offset   NUMERIC(3,1),
    raw_offset   NUMERIC(3,1)
);

CREATE TABLE continent_codes (
    code       CHAR(2),
    name       TEXT,
    geoname_id INTEGER
);

CREATE TABLE postal_codes (
    country_code CHAR(2),
    postal_code  CHAR(20),
    place_name   TEXT,
    admin1_name  TEXT,
    admin1_code  TEXT,
    admin2_name  TEXT,
    admin2_code  TEXT,
    admin3_name  TEXT,
    admin3_code  TEXT,
    latitude     FLOAT,
    longitude    FLOAT,
    accuracy     SMALLINT
);

-- static data (wait after import before creating referential integrity constraints)

INSERT INTO continent_codes VALUES ('AF', 'Africa', 6255146);
INSERT INTO continent_codes VALUES ('AS', 'Asia', 6255147);
INSERT INTO continent_codes VALUES ('EU', 'Europe', 6255148);
INSERT INTO continent_codes VALUES ('NA', 'North America', 6255149);
INSERT INTO continent_codes VALUES ('OC', 'Oceania', 6255150);
INSERT INTO continent_codes VALUES ('SA', 'South America', 6255151);
INSERT INTO continent_codes VALUES ('AN', 'Antarctica', 6255152);