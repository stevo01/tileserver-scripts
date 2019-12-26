#!/bin/bash

set -x

BASE=/storage_ssd/osm_replicate
FLATNODEFILE=/nodes/flat_nodes.bin
STYLE=/replication/src/openstreetmap-carto/openstreetmap-carto.style
LUA=/replication/src/openstreetmap-carto/openstreetmap-carto.lua
LOGFILE=/replication/work/import.log

export PGPASSWORD=renderer
PG_USER=renderer
PG_DBNAME=gis
PG_HOST=osmpsql

echo "initial import osm database" 2>&1 | tee $LOGFILE

echo "start import $(date)" 2>&1 | tee -a $LOGFILE
osm2pgsql -U $PG_USER -H $PG_HOST -d $PG_DBNAME --create -G -s --number-processes 4 -C16000 -S $STYLE --flat-nodes $FLATNODEFILE --hstore --tag-transform-script $LUA -p planet_osm_hstore $1 2>&1 | tee -a $LOGFILE
echo "end import $(date)" 2>&1 | tee -a $LOGFILE

# log database settings
psql -U $PG_USER -h $PG_HOST -d $PG_DBNAME -c "select name, setting from pg_settings" 2>&1 | tee -a $LOGFILE
