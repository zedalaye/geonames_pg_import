#!/bin/bash
#===============================================================================
#
# FILE: import.sh
#
# USAGE: ./import.sh
#
# DESCRIPTION: run the script so that the geodata will be downloaded and inserted
# into your database
#
# OPTIONS: ---
# REQUIREMENTS: a working PostgtreSQL instance with PostGIS extensions installed
# BUGS: ---
# NOTES: ---
# AUTHOR: Andreas (aka Harpagophyt)
# COMPANY: <a href="http://forum.geonames.org/gforum/posts/list/926.page" target="_blank" rel="nofollow">http://forum.geonames.org/gforum/posts/list/926.page</a>
# VERSION: 2.0
# CREATED: 07/06/2008
# REVISION:
# 1.1 2008-06-07 Replace COPY continentCodes through INSERT statements.
# 1.2 2008-11-25 Adjusted by Bastiaan Wakkie in order to not unnessarily download.
# 1.3 2011-08-07 Updated script with tree changes. Removes 2 obsolete records from "countryinfo" dump image,
#                updated timeZones table with raw_offset and updated postalcode to varchar(20).
# 1.4 2012-10-01 (Scott Wilson) Added is_historical and is_colloquial to alternate names table, and country
#                code to time zones.  Add column constraints after loading data, runs super fast on my machine.
#                Normalized column naming, various other tweaks.
# 2.0 2022-07-26 (Pierre Yager) massive upgrade, cleanup and refactoring
#                - database naming normalization (camel_cased everything)
#                - extracted tables cleanup script into cleanup.sql
#                - extracted tables creation script into schema.sql
#                - extracted indexing and referential integrity updates into integrity.sql
#                - restored import of postal_codes (with a hard cleanup of duplicates and invalid rows)
#                - added hierarchy.txt
#                - added adminCode5.txt
#                - switched to alternateNamesV2.txt
#                - read arguments on command line (--from-scratch, --drop and --create)
#                - added a help message (--help)
#                - factored out dowload_file(), cleanup_header() and cleanup_comments()
#===============================================================================
#!/bin/bash

help() {
  echo "Download and import GeoNames datasets into any PostgreSQL database"
  echo
  echo "Syntax:"
  echo "$0 --help"
  echo "$0 [--from-scrath] [--drop] [--create]"
  echo
  echo "Options:"
  echo "--from-scratch (-f)  Force download of datasets"
  echo "--drop (-d)          Drop tables before import"
  echo "--create (-c)        Create tables before import"
  echo "--get (-g)           Download/Update GeoNames datasets"
  echo "--import (-i)        Import GeoNames datasets"
  echo
  echo "Notes:"
  echo "You have several ways to define the database password if your connection"
  echo "requires one:"
  echo "Set the PGPASSWORD or DBPASSWORD environment variable in .env"
  echo "Pass the PGPASSWORD or DBPASSWORD environment variable in command line"
  echo "Like: PGPASSWORD=mypassword $0 [options]"
  exit 1
}

cleanup_header() {
  tail -n +2 $1 > $1.tmp
}

cleanup_comments() {
  grep -v '^#' $1 > $1.tmp
}

download_file() {
  local SCOPE=$1
  local FILE=$2

  wget -N -q "$ROOT_URL/$SCOPE/$FILE"
  if [ $FILE -nt "${PREFIX}${FILE}" ] || [ ! -e ${FILE} ]; then
    echo "| $SCOPE/${FILE} has been downloaded"

    cp ${FILE} "${PREFIX}${FILE}"
    if [[ ${FILE} == *.zip ]]; then
        unzip -u -q ${FILE}
        echo "| $SCOPE/${FILE} has been unpacked"
    fi

    return 0
  else
    echo "| $SCOPE/${FILE} is already the latest version"

    return 1
  fi
}

# Unless you really know what you are doing, you should not modify variables
# in this script. Please define/add/change yours in the .env file.

ROOT_URL="http://download.geonames.org/export/"
WORKPATH="."
TMPPATH="tmp"
PCPATH="pc"
PREFIX="_"

FILES=("allCountries.zip" "hierarchy.zip" "alternateNamesV2.zip" "userTags.zip")
FILES+=("admin1CodesASCII.txt" "admin2Codes.txt" "adminCode5.zip" "countryInfo.txt")
FILES+=("featureCodes_en.txt" "iso-languagecodes.txt" "timeZones.txt")

if [ -f ".env" ]; then
 . ".env"
else
  echo "Missing .env file (environment related configuration variables)"
  echo "Copy .env.example into .env and change variables according to your needs"
  echo "Mandatory environment variables are DBUSER and DATABASE"
  exit 1
fi

# Check environment and set defaults where possible
DBHOST="${DBHOST:-localhost}"
DBPORT="${DBPORT:-5432}"
DBUSER="${DBUSER:?Missing variable}"
DATABASE="${DATABASE:?Missing variable}"
SCHEMA="${SCHEMA:-public}"

# Get parameters from command line
CLEANUP_CACHE="false"
DROP_TABLES="false"
CREATE_TABLES="false"
DOWNLOAD_DATA="false"
IMPORT_DATA="false"

while [ $# -ne 0 ]; do
  case $1 in
    -h | --help)
      help
      ;;
    -f | --from-scratch)
      CLEANUP_CACHE="true"
      ;;
    -d | --drop)
      DROP_TABLES="true"
      ;;
    -c | --create)
      CREATE_TABLES="true"
      ;;
    -g | --get)
      DOWNLOAD_DATA="true"
      ;;
    -i | --import)
      IMPORT_DATA="true"
      ;;
    *)
      echo "Unknown parameter: $1"
      help
      ;;
  esac
  shift
done

# Forward PGPASSWORD
if [ -z "${PGPASSWORD}" ] && [ ! -z "${DBPASSWORD}" ]; then
  export PGPASSWORD="${DBPASSWORD}"
fi

# Prepare PGOPTIONS and short psql command options into PSQL_COMMAND
export PGOPTIONS="--search_path=${SCHEMA}"
PSQL_COMMAND="-U ${DBUSER} -h ${DBHOST} -p ${DBPORT} ${DATABASE}"

# Drop tables if required
if [[ "${DROP_TABLES}" == "true" ]]; then
    psql ${PSQL_COMMAND} < cleanup.sql
fi

# Create tables if required
if [[ "${CREATE_TABLES}" == "true" ]]; then
    psql ${PSQL_COMMAND} < schema.sql
fi

# Resolve WORKPATH as an absolute path
WORKPATH=$(readlink -f ${WORKPATH})

# Make sure WORKPATH/{tmp,pc} exists
echo "Ensure ${WORKPATH} and its subdirectories exists ..."
mkdir -p "${WORKPATH}"/{${TMPPATH},${PCPATH}}

# Clean WORKPATH if required
if [[ "${CLEANUP_CACHE}" == "true" ]]; then
  echo "Cleanup cached files in ${WORKPATH}..."
  rm -f "${WORKPATH}"/{${TMPPATH},${PCPATH}}/*
fi

if [[ "${DOWNLOAD_DATA}" == "true" ]]; then

  echo
  echo ",---- STARTING (downloading, unpacking and preparing)"

  # download and prepare datasets
  cd "${WORKPATH}/${TMPPATH}" || exit 1
  for i in "${FILES[@]}"; do
    download_file "dump" $i

    if [ $? -eq 0 ]; then
      case "$i" in
          iso-languagecodes.txt | timeZones.txt)
              cleanup_header "$i"
              echo "| $i has been fixed"
              ;;
          countryInfo.txt)
              cleanup_comments "$i"
              echo "| $i has been fixed"
              ;;
      esac
    fi
  done

  # download the postalcodes dataset
  cd "${WORKPATH}/${PCPATH}" || exit 1
  download_file "zip" "allCountries.zip"

  # go back to script home
  cd ${WORKPATH} || exit 1

fi

# import datasets
if [[ "${IMPORT_DATA}" == "true" ]]; then
  psql -e ${PSQL_COMMAND} << SQL
    \copy geoname (id, name, ascii_name, alternate_names, latitude, longitude,\
                  feature_class, feature_code, country, cc2, admin1, admin2,\
                  admin3, admin4, population, elevation, dem, timezone, modified_on)\
        from '${WORKPATH}/${TMPPATH}/allCountries.txt' null as '';

    \copy hierarchy (parent_id, child_id, type)\
        from '${WORKPATH}/${TMPPATH}/hierarchy.txt' null as '';

    \copy postal_codes (country_code, postal_code, place_name,\
                      admin1_name, admin1_code, admin2_name, admin2_code,\
                      admin3_name, admin3_code,\
                      latitude, longitude,accuracy)\
        from '${WORKPATH}/${PCPATH}/allCountries.txt' null as '';

    \copy time_zones (country_code, id, gmt_offset, dst_offset, raw_offset)\
        from '${WORKPATH}/${TMPPATH}/timeZones.txt.tmp' null as '';

    \copy feature_codes (code, name, description)\
        from '${WORKPATH}/${TMPPATH}/featureCodes_en.txt' null as '';

    \copy admin1_codes (code, name, name_ascii, geoname_id)\
        from '${WORKPATH}/${TMPPATH}/admin1CodesASCII.txt' null as '';

    \copy admin2_codes (code, name, name_ascii, geoname_id)\
        from '${WORKPATH}/${TMPPATH}/admin2Codes.txt' null as '';

    \copy admin5_codes (geoname_id, admin5)\
        from '${WORKPATH}/${TMPPATH}/adminCode5.txt' null as '';

    \copy iso_language_codes (iso_639_3, iso_639_2, iso_639_1, language_name)\
        from '${WORKPATH}/${TMPPATH}/iso-languagecodes.txt.tmp' null as '';

    \copy country_info (iso_alpha2, iso_alpha3, iso_numeric, fips_code, country,\
                        capital, area, population, continent, tld, currency_code,\
                        currency_name, phone, postal, postal_regex, languages,\
                        geoname_id, neighbours, equivalent_fips_code)\
        from '${WORKPATH}/${TMPPATH}/countryInfo.txt.tmp' null as '';

    \copy alternate_names (id,geoname_id, iso_language, alternate_name,\
                          is_preferred_name, is_short_name,\
                          is_colloquial, is_historic,\
                          usage_from, usage_to)\
        from '${WORKPATH}/${TMPPATH}/alternateNamesV2.txt' null as '';
SQL
fi

# create referential constraints and indexes
if [[ "${CREATE_TABLES}" == "true" ]]; then
  psql ${PSQL_COMMAND} < integrity.sql
fi

echo "----- DONE ( have fun... )"
