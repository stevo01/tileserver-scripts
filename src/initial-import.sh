#!/bin/bash

BASE=/storage_ssd/osm_replicate
FLATNODEFILE=$BASE/flatnode.dat
STYLE=/replication/src/openstreetmap-carto/openstreetmap-carto.style
LUA=/replication/src/openstreetmap-carto/openstreetmap-carto.lua

export PGPASSWORD=osm

osm2pgsql -G -d osm -U osm -s -C16000 -S $STYLE --flat-nodes $FLATNODEFILE --hstore --tag-transform-script $LUA -p planet_osm_hstore $1
