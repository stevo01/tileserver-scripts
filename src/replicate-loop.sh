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
export PGPASSWORD=renderer
PG_USER=renderer
PG_DBNAME=gis
PG_HOST=192.168.1.54

LOGFILE=/replication/work/replication.log

STARTIME=$(date)

# check if sequence file exists
if ! [ -f $SEQFILE ]
then
  >&2 echo "sequence file $SEQFILE does not exist"
  exit 1
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
      echo "other process ($OTHERPID) active"
      exit 1
   fi
fi

# create lockfile
echo $$ > $LOCKFILE

# calculate and show lag (in minutes)
START=`date +%s`
eval $(curl -s https://planet.osm.org/replication/minute/state.txt |grep sequenceNumber)
local_sequence=$(cat $SEQFILE)
LAG=$(expr $sequenceNumber - $local_sequence)

echo "start update: osmosis replication is ${LAG} minutes behind upstream"
echo "start update: osmosis replication is ${LAG} minutes behind upstream" >> $LOGFILE

THISFILE=$BASE/data/replicate-$START.osc
MERGEDFILE=$BASE/data/merged.osc

# make backup of the sequence file
if cp $BASE/data/sequence_file $BASE/data/sequence_file.old
then
   :
else
   >&2 echo "cannot make backup copy of sequence_file"
   rm $LOCKFILE
   exit 1
fi

# todo: describe the purpose of follwing line
find $BASE/data/ -name replicate-\*.osc -mtime +0 | xargs rm -f

# fetch diff files from osm webpage
#  $SEQFILE: the sequence file includes the start sequence number at startup (input value for pyosmium-get-changes )
#            and the sequence number for next replication procedure (output value of pyosmium-get-changes )
#  $THISFILE: this file includes the osm data fetched by the script
pyosmium-get-changes -s 500 -f $SEQFILE -o $THISFILE

# for test purposes only
cat $SEQFILE

# check if the osm diff file excists
if [ ! -f $THISFILE ]
then
   # exit the script
   >&2 echo "pyosmium-get-changes error"
   rm $LOCKFILE
   exit 1
else
  echo "pyosmium-get-changes passed" >> $LOGFILE
fi

# check if mergefile excists
if [ -f $MERGEDFILE ]
then
   # something left over from last time
   echo "merging with existing diff"
   echo "merging with existing diff" >> $LOGFILE
   if [ -f $BASE/data/osmium-mc.stderr ]; then
     mv $BASE/data/osmium-mc.stderr $BASE/data/osmium-mc.stderr.old
   fi
   if osmium merge-changes --no-progress -s -o $MERGEDFILE-new.osc $THISFILE $MERGEDFILE 2>$BASE/data/osmium-mc.stderr
   then
      mv $MERGEDFILE-new.osc $MERGEDFILE
   else
      >&2 echo "osmium error"
      echo "osmium error" >> $LOGFILE
      rm $LOCKFILE
      exit 1
   fi
else
   cp $THISFILE $MERGEDFILE
fi

if [ -f $BASE/data/osm2pgsql.stderr ]
then
  mv $BASE/data/osm2pgsql.stderr $BASE/data/osm2pgsql.stderr.old
fi

echo "start osm2pgsql"
echo "start osm2pgsql" >> $LOGFILE

if osm2pgsql -U $PG_USER -H $PG_HOST -d $PG_DBNAME -G -a -s --number-processes=1 -C4000 -S $STYLE --flat-nodes $FLATNODEFILE -e $(($MINZOOM-3))-16 -o $EXPIRELOG --expire-bbox-size 20000 --hstore --tag-transform-script $LUA $MERGEDFILE >$BASE/data/osm2pgsql.stdout 2>$BASE/data/osm2pgsql.stderr

then
   echo "osm2pgsql passed" >> $LOGFILE
   rm $MERGEDFILE
else
   >&2 echo "error in osm2pgsql"
   echo "error in osm2pgsql" >> $LOGFILE
   rm $LOCKFILE
   exit 1
fi

local_sequence=$(cat $SEQFILE)
LAG=$(expr $sequenceNumber - $local_sequence)
echo "end update: osmosis replication is ${LAG} minutes behind upstream"
echo "end update: osmosis replication is ${LAG} minutes behind upstream" >> $LOGFILE

if [ -f $BASE/data/doexpire ]; then
  sort -u $EXPIRELOG >$EXPIRELOG.uniq
  mv $EXPIRELOG.uniq $EXPIRELOG
  explog=$(expiremeta.pl --map=mapnikde --minzoom=$MINZOOM <$EXPIRELOG)
  echo "expire: $explog"
  /usr/local/bin/expirehrb
  mv $EXPIRELOG $EXPIRELOG.old
  rm $BASE/data/doexpire
fi

# remove lockfile
rm $LOCKFILE
