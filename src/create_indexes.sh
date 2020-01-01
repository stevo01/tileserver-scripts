#!/bin/bash

set -x

LOGFILE=/replication/work/create_indexes.log

export PGPASSWORD=renderer
PG_USER=renderer
PG_DBNAME=gis
PG_HOST=osmpsql


function log_info {
    today=`date +%Y-%m-%d.%H:%M:%S`
    echo "[INFO ] $today $1" 2>&1 | tee -a $LOGFILE
}

log_info "start create indexes"
cd /replication/src/openstreetmap-carto
scripts/indexes.py | psql -U $PG_USER -h $PG_HOST -d $PG_DBNAME 2>&1 | tee -a $LOGFILE
log_info "end create indexes"
