#!/bin/bash
set -x
LANG=C

BASE=/replication/work
FLATNODEFILE=/nodes/flat_nodes.bin
EXPIRELOG=$BASE/expire.log
SEQFILE=$BASE/data/sequence_file
STYLE=/replication/src/openstreetmap-carto/openstreetmap-carto.style
LUA=/replication/src/openstreetmap-carto/openstreetmap-carto.lua
MINZOOM=13
LOGFILE=/replication/work/replication.log

export PGPASSWORD=renderer
PG_USER=renderer
PG_DBNAME=gis
PG_HOST=osmpsql

function log_info {
    today=`date +%Y-%m-%d.%H:%M:%S`
    echo "[INFO ] $today $1" 2>&1 | tee -a $LOGFILE
}

function log_error {
    today=`date +%Y-%m-%d.%H:%M:%S`
    echo "[ERROR] $today $1" 2>&1 | tee -a $LOGFILE
    exit 1
}


# check if sequence file exists
if ! [ -f $SEQFILE ]
then
  log_error "error: sequence file $SEQFILE does not exist"
fi

LOCKFILE=$BASE/data/replicate.lock

# check if lockfile excists
if [ -f $LOCKFILE ]
then
   # read pid
   OTHERPID=`cat $LOCKFILE`

   # check if process is still active
   if kill -0 $OTHERPID 2>/dev/null
   then
      # exit script if another instance if script is running
      log_error "other process ($OTHERPID) active"
   fi
fi

# create lockfile
log_info "bgn replication $(date)"

# calculate and show lag (in minutes)
START=`date +%s`
eval $(curl -s https://planet.osm.org/replication/minute/state.txt |grep sequenceNumber)
local_sequence=$(cat $SEQFILE)
LAG=$(expr $sequenceNumber - $local_sequence)

log_info "start update: osmosis replication is ${LAG} minutes behind upstream"

THISFILE=$BASE/data/replicate-$START.osc
MERGEDFILE=$BASE/data/merged.osc

# make backup of the sequence file
if cp $BASE/data/sequence_file $BASE/data/sequence_file.old
then
  log_info "make backup copy of sequence_file"
  :
else
  rm $LOCKFILE
  log_error "cannot make backup copy of sequence_file"
fi

# todo: describe the purpose of follwing line
find $BASE/data/ -name replicate-\*.osc -mtime +0 | xargs rm -f

# fetch diff files from osm webpage
#  $SEQFILE: the sequence file includes the start sequence number at startup (input value for pyosmium-get-changes )
#            and the sequence number for next replication procedure (output value of pyosmium-get-changes )
#  $THISFILE: this file includes the osm data fetched by the script
log_info "bgn: pyosmium-get-changes sequence=$(cat $SEQFILE)"
pyosmium-get-changes -s 500 -f $SEQFILE -o $THISFILE
log_info "end: pyosmium-get-changessequence=$(cat $SEQFILE)"

# check if the osm diff file excists
if [ ! -f $THISFILE ]
then
   # exit the script
   rm $LOCKFILE
   log_error "pyosmium-get-changes error"
else
  log_info "pyosmium-get-changes passed $THISFILE"
fi

# check if mergefile excists
if [ -f $MERGEDFILE ]
then
   # something left over from last time
   log_info "merging with existing diff"
   if [ -f $BASE/data/osmium-mc.stderr ]; then
     mv $BASE/data/osmium-mc.stderr $BASE/data/osmium-mc.stderr.old
   fi
   if osmium merge-changes --no-progress -s -o $MERGEDFILE-new.osc $THISFILE $MERGEDFILE 2>$BASE/data/osmium-mc.stderr
   then
      log_info "osmium passed"
      mv $MERGEDFILE-new.osc $MERGEDFILE
   else
      rm $LOCKFILE
      log_error "osmium failed"
   fi
else
   log_info "skip merging with existing diff"
   cp $THISFILE $MERGEDFILE
fi

if [ -f $BASE/data/osm2pgsql.stderr ]
then
  mv $BASE/data/osm2pgsql.stderr $BASE/data/osm2pgsql.stderr.old
fi

log_info "start osm2pgsql"

if osm2pgsql -U $PG_USER -H $PG_HOST -d $PG_DBNAME -G -a -s --number-processes=1 -C16000 -S $STYLE --flat-nodes $FLATNODEFILE -e $(($MINZOOM-3))-16 -o $EXPIRELOG --expire-bbox-size 20000 --hstore --tag-transform-script $LUA $MERGEDFILE >$BASE/data/osm2pgsql.stdout 2>$BASE/data/osm2pgsql.stderr
then
   log_info "osm2pgsql passed"
   rm $MERGEDFILE
else
   rm $LOCKFILE
   log_error "error in osm2pgsql"
fi

local_sequence=$(cat $SEQFILE)
LAG=$(expr $sequenceNumber - $local_sequence)
log_info "end update: osmosis replication is ${LAG} minutes behind upstream"

if [ -f $BASE/data/doexpire ]; then
  sort -u $EXPIRELOG >$EXPIRELOG.uniq
  mv $EXPIRELOG.uniq $EXPIRELOG
  explog=$(expiremeta.pl --map=mapnikde --minzoom=$MINZOOM <$EXPIRELOG)
  log_info "expire: $explog"
  /usr/local/bin/expirehrb
  mv $EXPIRELOG $EXPIRELOG.old
  rm $BASE/data/doexpire
fi

# remove lockfile
rm $LOCKFILE
log_info "end replication $(date)"
