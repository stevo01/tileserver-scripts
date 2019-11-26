#!/bin/bash
set -x

export PGPASSWORD=renderer
PG_USER=renderer
PG_DBNAME=gis
PG_HOST=192.168.1.54

psql -d $PG_DBNAME --dbname $PG_DBNAME --host $PG_HOST --username $PG_USER \
     -c "select max(osm_id) from planet_osm_point;"

 
