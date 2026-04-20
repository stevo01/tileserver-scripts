# Replication and tile expire scripts from German tileserver

This repository contains the scripts which are used on the German
tileservers for database replication using pyosmium-get-changes and
osm2pgsql. These scripts will also trigger the tile expire mechanism from
the output created by osm2pgsql.

The machines are currently running Debian GNU/Linux 10 (buster) and most of
the software running there is available directly from the distribution.

Exceptions are:

* osml10n https://github.com/giggls/mapnik-german-l10n
* tirex https://github.com/openstreetmap/tirex
* libapache2-mod-tile https://github.com/openstreetmap/mod_tile/

## Provided scripts

### whichdiff.pl
A perl script to determine the replication number for the first sequence.
This is needed for bootstraping the replication process.

### expiremeta.pl
A perl script which will mark all meta-tiles read from osm2pgsql tile expire
file for re-rendering.

### expirehrb
A shell script which will mark our special small area Sorbian meta-tiles for re-rendering
based on the ones marked by expiremeta.pl.

### osm-replicate.service
Systemd service-file for running replicate-loop.sh

### osm-replicate.timer
Systemd timer-file for calling osm-replicate.service

### replicate-loop.sh

A shell script which fetches diff-files from OSM Planet server using pyosmium-get-changes
and feed them to osm2pgsql afterwards. It will also call tile expire scripts
if requested. This script is intended to be called from a cronjob or
(recommend) from the provided systemd service and timer files. If you
intend to use this for your own tileserver you will likely need to slightly adapt
this to your own requirements.


## database debugging / analysis

### connect to database
psql -h osmpsql -U renderer gis

### show all tables
\dt

## shows size of db
SELECT
   relname as "Table",
   pg_size_pretty(pg_total_relation_size(relid)) As "Size",
   pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) as "External Size"
   FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC;

             Table             |  Size   | External Size 
-------------------------------+---------+---------------
 planet_osm_ways               | 766 GB  | 500 GB
 planet_osm_polygon            | 353 GB  | 125 GB
 planet_osm_line               | 251 GB  | 76 GB
 planet_osm_point              | 62 GB   | 21 GB
 planet_osm_roads              | 23 GB   | 10124 MB
 planet_osm_rels               | 16 GB   | 7663 MB
 spatial_ref_sys               | 4808 kB | 224 kB
 planet_osm_replication_status | 48 kB   | 40 kB
(8 rows)

gis=>  VACUUM(FULL, ANALYZE, VERBOSE) planet_osm_point;


## shrink database table
VACUUM(FULL, ANALYZE, VERBOSE) planet_osm_point;


## shrink
shrink logfiles
