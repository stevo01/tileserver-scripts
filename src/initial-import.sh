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


function log_info {
    today=`date +%Y-%m-%d.%H:%M:%S`
    echo "[INFO ] $today $1" 2>&1 | tee -a $LOGFILE
}

loginfo "start initial import of database $(date)"
osm2pgsql -U $PG_USER -H $PG_HOST -d $PG_DBNAME --create -G -s --number-processes 4 -C16000 -S $STYLE --flat-nodes $FLATNODEFILE --hstore --tag-transform-script $LUA $1 2>&1 | tee -a $LOGFILE
loginfo "end import $(date)" 2>&1 | tee -a $LOGFILE

# log database settings
psql -U $PG_USER -h $PG_HOST -d $PG_DBNAME -c "select name, setting from pg_settings" 2>&1 | tee -a $LOGFILE
