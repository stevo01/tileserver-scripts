#!/bin/bash

BASE=/storage_ssd/osm_replicate
FLATNODEFILE=$BASE/flatnode.dat
STYLE=/etc/mapnik-osm-data/openstreetmap-carto-de/hstore-only.style
LUA=/etc/mapnik-osm-data/openstreetmap-carto-de/openstreetmap-carto.lua

export PGPASSWORD=osm

osm2pgsql -G -d osm -U osm -s -C16000 -S $STYLE --flat-nodes $FLATNODEFILE --hstore --tag-transform-script $LUA -p planet_osm_hstore $1

