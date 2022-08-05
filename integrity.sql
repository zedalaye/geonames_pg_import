-- remove duplicates

DELETE FROM postal_codes p1 USING postal_codes p2
WHERE p1.ctid > p2.ctid
  AND p2.country_code = p1.country_code
  AND p2.postal_code = p1.postal_code
  AND p2.place_name = p1.place_name;

DELETE FROM postal_codes
WHERE place_name is null;


-- primary keys

ALTER TABLE geoname
    ADD CONSTRAINT pk_geoname_id
        PRIMARY KEY (id);

ALTER TABLE alternate_names
    ADD CONSTRAINT pk_alternate_name_id
        PRIMARY KEY (id);

ALTER TABLE country_info
    ADD CONSTRAINT pk_iso_alpha2
        PRIMARY KEY (iso_alpha2);

ALTER TABLE admin1_codes
    ADD CONSTRAINT pk_admin1_code
        PRIMARY KEY (code);

ALTER TABLE admin2_codes
    ADD CONSTRAINT pk_admin2_code
        PRIMARY KEY (code);

ALTER TABLE admin5_codes
    ADD CONSTRAINT pk_admin5_geoname_id
        PRIMARY KEY (geoname_id);

ALTER TABLE continent_codes
    ADD CONSTRAINT pk_continent_code
        PRIMARY KEY (code);

ALTER TABLE feature_codes
    ADD CONSTRAINT pk_feature_code
        PRIMARY KEY (code);

ALTER TABLE iso_language_codes
    ADD CONSTRAINT pk_iso_639_3
        PRIMARY KEY (iso_639_3);

ALTER TABLE postal_codes
    ADD CONSTRAINT pk_postal_code
        PRIMARY KEY (country_code, postal_code, place_name);

ALTER TABLE time_zones
    ADD CONSTRAINT pk_time_zone_id
        PRIMARY KEY (id);


-- foreign keys

CREATE INDEX index_hierarchy_parent_id
    ON hierarchy(parent_id);

CREATE INDEX index_hierarchy_child_id
    ON hierarchy(child_id);

ALTER TABLE hierarchy
  ADD CONSTRAINT fk_hierarchy_geoname_parent_id
      FOREIGN KEY (parent_id)
      REFERENCES geoname(id);

ALTER TABLE hierarchy
  ADD CONSTRAINT fk_hierarchy_geoname_child_id
      FOREIGN KEY (child_id)
      REFERENCES geoname(id);


CREATE INDEX index_country_info_geoname_id
    ON country_info (geoname_id);

ALTER TABLE ONLY country_info
    ADD CONSTRAINT fk_country_info_geoname_id
        FOREIGN KEY (geoname_id)
        REFERENCES geoname(id);


CREATE INDEX index_admin1_codes_geoname_id
    ON admin1_codes (geoname_id);

ALTER TABLE ONLY admin1_codes
    ADD CONSTRAINT fk_admin1_codes_geoname_id
        FOREIGN KEY (geoname_id)
        REFERENCES geoname(id);


CREATE INDEX index_admin2_codes_geoname_id
    ON admin2_codes (geoname_id);

ALTER TABLE ONLY admin2_codes
    ADD CONSTRAINT fk_admin2_codes_geoname_id
        FOREIGN KEY (geoname_id)
        REFERENCES geoname(id);

-- admin5_codes.geoname_id is already indexed by primary key
ALTER TABLE ONLY admin5_codes
    ADD CONSTRAINT fk_admin5_codes_geoname_id
        FOREIGN KEY (geoname_id)
        REFERENCES geoname(id);


CREATE INDEX index_alternate_names_geoname_id
    ON alternate_names (geoname_id);

ALTER TABLE ONLY alternate_names
    ADD CONSTRAINT fk_alternate_names_geoname_id
        FOREIGN KEY (geoname_id)
        REFERENCES geoname(id);

/*
   Add unicode flags to country_info
   Unicode Flags are made using two Regional Indicators characters corresponding to the iso_alpha2 country code
   "A" Regional Indicator is at \u1f1e6
   RIc = char(ascii(Letter) - ascii('A) + x'1f1e6'::int)
   as "A" ascii char is at 0x41: - x'41'::int + x'1f1e6'::int = x'1f1a5'::int
 */
ALTER TABLE country_info
  ADD COLUMN flag CHAR(2)
    GENERATED ALWAYS AS (
        chr(ascii(substring(iso_alpha2, 1, 1)) + x'1f1a5'::int)
     || chr(ascii(substring(iso_alpha2, 2, 1)) + x'1f1a5'::int)
    ) STORED;

-- Should be ran after data import
ALTER TABLE geoname
    ADD COLUMN search_vector tsvector
        GENERATED ALWAYS AS (to_tsvector('english',
          coalesce(name, '') || ' ' || coalesce(ascii_name, '') || ' ' || coalesce(alternate_names, '')
        )) STORED;

CREATE INDEX geoname_search_vector_idx
    ON geoname USING gin (search_vector);

-- Index for similarity comparisons
CREATE INDEX geoname_ascii_name_trgm_idx
    ON geoname USING gin (ascii_name gin_trgm_ops);
