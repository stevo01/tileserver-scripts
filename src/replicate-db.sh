#!/bin/bash

export PGPASSWORD=renderer
PG_USER=renderer
PG_DBNAME=gis
PG_HOST=osmpsql
FLATNODEFILE=/nodes/flat_nodes.bin
STYLE=/replication/src/openstreetmap-carto/openstreetmap-carto.style
LUA=/replication/src/openstreetmap-carto/openstreetmap-carto.lua
LOCKFILE=/replication/work/data/replicate.lock

OSMPGSQL_LOGFILE=/replication/work/data/osm2pgsql.stdout

# check if lockfile excists
if [ -f $LOCKFILE ]
then
   # read pid
   OTHERPID=`cat $LOCKFILE`

   # check if process is still active
   if kill -0 $OTHERPID 2>/dev/null
   then
      # exit script if another instance if script is running
      echo "other process ($OTHERPID) active"
      exit 1
   fi
fi

# create lockfile
echo $$ > $LOCKFILE

/replication/src/osm2pgsql/scripts/osm2pgsql-replication update \
			-d $PG_DBNAME -H $PG_HOST -U $PG_USER -v --max-diff-size 500 --once \
			-- -G --number-processes=1 -S $STYLE --flat-nodes $FLATNODEFILE \
			--hstore --tag-transform-script $LUA 2>&1 | tee -a $OSMPGSQL_LOGFILE

# remove lockfile
rm $LOCKFILE