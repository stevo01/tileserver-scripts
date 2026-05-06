#!/bin/bash
set -euo pipefail
set -x

FLATNODEFILE="/nodes/flat_nodes.bin"
STYLE="/replication/src/openstreetmap-carto/openstreetmap-carto.style"
LUA="/replication/src/openstreetmap-carto/openstreetmap-carto.lua"

LOGFILE="/replication/work/import.log"

export PGPASSWORD="renderer"
PG_USER="renderer"
PG_DBNAME="gis"
PG_HOST="osmpsql"

log_info() {
    local now
    now="$(date +%Y-%m-%d.%H:%M:%S)"
    echo "[INFO ] $now $1" | tee -a "$LOGFILE"
}

if [[ -z "${1:-}" ]]; then
    log_info "ERROR: No input file specified"
    exit 1
fi

if [[ ! -f "$1" ]]; then
    log_info "ERROR: Input file '$1' does not exist"
    exit 1
fi


psql -U "$PG_USER" -h "$PG_HOST" -d "$PG_DBNAME" -c "CREATE EXTENSION hstore;"


log_info "start initial import of database"

osm2pgsql \
    -U "$PG_USER" \
    -H "$PG_HOST" \
    -d "$PG_DBNAME" \
    --create \
    --slim \
    --hstore \
    --number-processes 8 \
    --cache=16000 \
    --style "$STYLE" \
    --flat-nodes "$FLATNODEFILE" \
    --tag-transform-script "$LUA" \
    "$1" 2>&1 | tee -a "$LOGFILE"

log_info "end import"

# --output=flex 

psql -U "$PG_USER" -h "$PG_HOST" -d "$PG_DBNAME" \
    -c "select name, setting from pg_settings" 2>&1 | tee -a "$LOGFILE"
