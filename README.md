# Import GeoNames datasets into any PostgreSQL database

Use it to download, unpack and import [GeoNames](https://geonames.org) datasets in any PostgreSQL database.

## Acknowledgments

This script is based on

https://gist.github.com/EspadaV8/1357237/25a81f06fd1d04b54cdda35a53f359c45aefce6a
and https://gist.github.com/WhoAteDaCake/37823722bdf27fc03527f5b54c0ca6f0

Many thanks to [GeoNames](https://geonames.org) for making these datasets publicly available.

Thanks to *Andreas (aka Harpagophyt)* and *Scott Wilson* for their previous work on this script.

## Prerequisites

A working PostgreSQL instance with PostGIS extensions installed.

This script has been tested against PostgreSQL 14

You will also need the `wget` and `unzip` command line tools.

## Usage

Copy `.env.example` and change variables according to your needs/environment.

`DATABASE` and `DB_USER` variables are mandatory, other variables will get default values.

`PGPASSWORD` (or `DBPASSWORD`) can be specified in the `.env` file or in the command line :

```bash
PGPASSWORD=mypassword ./import.sh -d -c -g -i
```

* `-d (--drop)` will drop existing tables
* `-c (--create)` will recreate tables and after import it will add integrity constraints (primary and foreign keys) and some indexes.
* `-f (--from-scratch)` will force download of GeoNames datasets
* `-g (--get)` will download GeoNames datasets
* `-i (--import)` will import GeoNames datasets

For subsequent imports, you can also clean the download cache to start from scratch by using the `-f (--from-scratch)` argument.
