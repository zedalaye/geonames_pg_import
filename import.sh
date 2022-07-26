#!/bin/bash
#===============================================================================
#
# FILE: getgeo.sh
#
# USAGE: ./getgeo.sh
#
# DESCRIPTION: run the script so that the geodata will be downloaded and inserted into your
# database
#
# OPTIONS: ---
# REQUIREMENTS: ---
# BUGS: ---
# NOTES: ---
# AUTHOR: Andreas (aka Harpagophyt )
# COMPANY: <a href="http://forum.geonames.org/gforum/posts/list/926.page" target="_blank" rel="nofollow">http://forum.geonames.org/gforum/posts/list/926.page</a>
# VERSION: 1.3
# CREATED: 07/06/2008/
# REVISION: 1.1 2008-06-07 replace COPY continentCodes through INSERT statements.
# 1.2 2008-11-25 Adjusted by Bastiaan Wakkie in order to not unnessisarily
# download.
# 1.3 2011-08-07 Updated script with tree changes. Removes 2 obsolete records from "countryinfo" dump image,
#                updated timeZones table with raw_offset and updated postalcode to varchar(20).
# 1.4 2012-10-01 (Scott Wilson) Added is_historical and is_colloquial to alternate names table, and country
#                code to time zones.  Add column constraints after loading data, runs super fast on my machine.
#                Normalized column naming, various other tweaks.
#===============================================================================
#!/bin/bash

WORKPATH="/tmp/geonames.work"
TMPPATH="tmp"
PCPATH="pc"
PREFIX="_"
DBHOST="host"
DBPORT="5432"
DBUSER="user"
DATABASE="postgres"
SCHEMA="postgis"
FILES="allCountries.zip alternateNames.zip userTags.zip admin1CodesASCII.txt admin2Codes.txt countryInfo.txt featureCodes_en.txt iso-languagecodes.txt timeZones.txt"
DROP_TABLES="false"
CREATE_TABLES="false"

export PGOPTIONS="--search_path=${SCHEMA}"

if [[ "$DROP_TABLES" == "true" ]]; then

    psql -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE << EOF
        DROP TABLE IF EXISTS geoname CASCADE;
        DROP TABLE IF EXISTS alternatename;
        DROP TABLE IF EXISTS countryinfo;
        DROP TABLE IF EXISTS iso_languagecodes;
        DROP TABLE IF EXISTS admin1CodesAscii;
        DROP TABLE IF EXISTS admin2CodesAscii;
        DROP TABLE IF EXISTS featureCodes;
        DROP TABLE IF EXISTS timeZones;
        DROP TABLE IF EXISTS continentCodes;
        DROP TABLE IF EXISTS postalcodes;
EOF

fi


if [[ "$CREATE_TABLES" == "true" ]]; then
    psql -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE << EOF

    CREATE TABLE geoname (
        id              INT,
        name            TEXT,
        ascii_name      TEXT,
        alternate_names TEXT,
        latitude        FLOAT,
        longitude       FLOAT,
        fclass          CHAR(1),
        fcode           CHAR(10),
        country         CHAR(2),
        cc2             TEXT,
        admin1          TEXT,
        admin2          TEXT,
        admin3          TEXT,
        admin4          TEXT,
        population      BIGINT,
        elevation       INT,
        gtopo30         INT,
        timezone        TEXT,
        modified_date   DATE
    );
    CREATE TABLE alternatename (
        id                INT,
        geoname_id        INT,
        iso_lang          TEXT,
        alternate_name    TEXT,
        is_preferred_name BOOLEAN,
        is_short_name     BOOLEAN,
        is_colloquial     BOOLEAN,
        is_historic       BOOLEAN
    );
    CREATE TABLE countryinfo (
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
        geoname_id           INT,
        neighbours           TEXT,
        equivalent_fips_code TEXT
    );
    CREATE TABLE iso_languagecodes(
        iso_639_3     CHAR(4),
        iso_639_2     TEXT,
        iso_639_1     TEXT,
        language_name TEXT
    );

    CREATE TABLE admin1CodesAscii (
        code       CHAR(20),
        name       TEXT,
        name_ascii  TEXT,
        geoname_id INT
    );
    CREATE TABLE admin2CodesAscii (
        code      CHAR(80),
        name      TEXT,
        name_ascii TEXT,
        geoname_id INT
    );
    CREATE TABLE featureCodes (
        code        CHAR(7),
        name        TEXT,
        description TEXT
    );
    CREATE TABLE timeZones (
        id           TEXT,
        country_code TEXT,
        GMT_offset NUMERIC(3,1),
        DST_offset NUMERIC(3,1),
        raw_offset NUMERIC(3,1)
    );
    CREATE TABLE continentCodes (
        code       CHAR(2),
        name       TEXT,
        geoname_id INT
    );
    CREATE TABLE postalcodes (
        country_code CHAR(2),
        postal_code  TEXT,
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
EOF
fi

# check if needed directories do already exsist
if [ -d "$WORKPATH" ]; then
    echo "$WORKPATH exists..."
    sleep 0
else
    echo "$WORKPATH and subdirectories will be created..."
    mkdir -p $WORKPATH/{$TMPPATH,$PCPATH}
    echo "created $WORKPATH"
fi

echo
echo ",---- STARTING (downloading, unpacking and preparing)"
cd $WORKPATH/$TMPPATH
for i in $FILES
do
    wget -N -q "http://download.geonames.org/export/dump/$i" # get newer files
    if [ $i -nt $PREFIX$i ] || [ ! -e $PREFIX$i ] ; then
        cp -p $i $PREFIX$i
        if [[ $i == *.zip ]]
        then
          unzip -u -q $i
        fi
        
        case "$i" in
            iso-languagecodes.txt)
                tail -n +2 iso-languagecodes.txt > iso-languagecodes.txt.tmp;
                ;;
            countryInfo.txt)
                grep -v '^#' countryInfo.txt > countryInfo.txt.tmp;
                ;;
            timeZones.txt)
                tail -n +2 timeZones.txt > timeZones.txt.tmp;
                ;;
        esac
        echo "| $i has been downloaded";
    else
        echo "| $i is already the latest version"
    fi
done


psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE << EOF
\copy geoname (id,name,ascii_name,alternate_names,latitude,\
              longitude,fclass,fcode,country,cc2,admin1,admin2,\
              admin3,admin4,population,elevation,gtopo30,\
              timezone,modified_date)\
    from '${WORKPATH}/${TMPPATH}/allCountries.txt' null as '';

\copy timeZones (country_code,id,GMT_offset,DST_offset,raw_offset)\
    from '${WORKPATH}/${TMPPATH}/timeZones.txt.tmp' null as '';

\copy featureCodes (code,name,description)\
    from '${WORKPATH}/${TMPPATH}/featureCodes_en.txt' null as '';

\copy admin1CodesAscii (code,name,name_ascii,geoname_id)\
    from '${WORKPATH}/${TMPPATH}/admin1CodesASCII.txt' null as '';

\copy admin2CodesAscii (code,name,name_ascii,geoname_id)\
    from '${WORKPATH}/${TMPPATH}/admin2Codes.txt' null as '';

\copy iso_languagecodes (iso_639_3,iso_639_2,iso_639_1,language_name)\
    from '${WORKPATH}/${TMPPATH}/iso-languagecodes.txt.tmp' null as '';

\copy countryInfo (iso_alpha2,iso_alpha3,iso_numeric,fips_code,country,\
                  capital,area,population,continent,tld,currency_code,\
                  currency_name,phone,postal,postal_regex,languages,\
                  geoname_id,neighbours,equivalent_fips_code)\
    from '${WORKPATH}/${TMPPATH}/countryInfo.txt.tmp' null as '';

\copy alternatename (id,geoname_id,iso_lang,alternate_name,\
                    is_preferred_name,is_short_name,\
                    is_colloquial,is_historic)\
    from '${WORKPATH}/${TMPPATH}/alternateNames.txt' null as '';

INSERT INTO continentCodes VALUES ('AF', 'Africa', 6255146);
INSERT INTO continentCodes VALUES ('AS', 'Asia', 6255147);
INSERT INTO continentCodes VALUES ('EU', 'Europe', 6255148);
INSERT INTO continentCodes VALUES ('NA', 'North America', 6255149);
INSERT INTO continentCodes VALUES ('OC', 'Oceania', 6255150);
INSERT INTO continentCodes VALUES ('SA', 'South America', 6255151);
INSERT INTO continentCodes VALUES ('AN', 'Antarctica', 6255152);
CREATE INDEX concurrently index_countryinfo_geonameid ON countryinfo (geoname_id);
CREATE INDEX concurrently index_alternatename_geonameid ON alternatename (geoname_id);

EOF

psql -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE << EOF
ALTER TABLE ONLY alternatename
    ADD CONSTRAINT pk_alternatenameid PRIMARY KEY (id);
ALTER TABLE ONLY geoname
    ADD CONSTRAINT pk_geonameid PRIMARY KEY (id);
ALTER TABLE ONLY countryinfo
    ADD CONSTRAINT pk_iso_alpha2 PRIMARY KEY (iso_alpha2);
ALTER TABLE ONLY countryinfo
    ADD CONSTRAINT fk_geonameid FOREIGN KEY (geoname_id)
        REFERENCES geoname(id);
ALTER TABLE ONLY alternatename
    ADD CONSTRAINT fk_geonameid FOREIGN KEY (geoname_id)
        REFERENCES geoname(id);
-- Should be ran after data import

alter table geoname
	add search_vector tsvector;

-- Run time arround: 16 minutes
update geoname
set search_vector = to_tsvector('english', concat_ws(' ', name, ascii_name, alternate_names)) 
where true;


-- Index for fast vector search
-- Run time: 13m
create index concurrently geoname_search_vector_idx
    on geoname using gin (search_vector);

-- Index for similarity comparisons
-- RUn time: 5 minutes
CREATE INDEX concurrently trgm_idx ON geoname USING gin (ascii_name extensions.gin_trgm_ops);
EOF

echo "----- DONE ( have fun... )"
