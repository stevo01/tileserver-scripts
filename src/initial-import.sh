#!/bin/bash

set -x

BASE=/storage_ssd/osm_replicate
FLATNODEFILE=/nodes/flat_nodes.bin
STYLE=/replication/src/openstreetmap-carto/openstreetmap-carto.style
LUA=/replication/src/openstreetmap-carto/openstreetmap-carto.lua

export PGPASSWORD=renderer
PG_USER=renderer
PG_DBNAME=gis
PG_HOST=osmpsql

echo $date
osm2pgsql -U $PG_USER -H $PG_HOST -d $PG_DBNAME --create -G -s -C16000 -S $STYLE --flat-nodes $FLATNODEFILE --hstore --tag-transform-script $LUA -p planet_osm_hstore $1
echo $date
