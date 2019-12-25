#!/bin/bash

set -x

export PGPASSWORD=renderer
PG_USER=renderer
PG_DBNAME=gis
PG_HOST=osmpsql
LOGFILE=test-db.log

psql -U $PG_USER -h $PG_HOST -d $PG_DBNAME -c "select max(osm_id) from planet_osm_point;" 2>&1 | tee $LOGFILE
