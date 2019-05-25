#!/bin/bash
#set -x
LANG=C

BASE=/storage_ssd/osm_replicate
FLATNODEFILE=$BASE/flatnode.dat
EXPIRELOG=$BASE/expire.log
SEQFILE=$BASE/data/sequence_file
STYLE=/etc/mapnik-osm-data/openstreetmap-carto-de/hstore-only.style
LUA=/etc/mapnik-osm-data/openstreetmap-carto-de/openstreetmap-carto.lua
MINZOOM=13
export PGPASSWORD=osm

# check if sequence file exists
if ! [ -f $SEQFILE ]
then
  >&2 echo "sequence file $SEQFILE does not exist"
  exit 1
fi

LOCKFILE=$BASE/data/replicate.lock

if [ -f $LOCKFILE ] 
then
   OTHERPID=`cat $LOCKFILE`
   if kill -0 $OTHERPID 2>/dev/null
   then
      # other process running
      echo "other process ($OTHERPID) active"
      exit 1
   fi
fi

echo $$ > $LOCKFILE

START=`date +%s`
eval $(curl -s https://planet.osm.org/replication/minute/state.txt |grep sequenceNumber)
local_sequence=$(cat $SEQFILE)
LAG=$(expr $sequenceNumber - $local_sequence)

echo "start update; osmosis replication is ${LAG} minutes behind upstream"

THISFILE=$BASE/data/replicate-$START.osc
MERGEDFILE=$BASE/data/merged.osc

if cp $BASE/data/sequence_file $BASE/data/sequence_file.old 
then
   :
else
   >&2 echo "cannot make backup copy of sequence_file"
   rm $LOCKFILE
   exit 1
fi

find $BASE/data/ -name replicate-\*.osc -mtime +0 | xargs rm -f

pyosmium-get-changes -s 500 -f $SEQFILE -o $THISFILE

if [ ! -f $THISFILE ]
then
   >&2 echo "pyosmium-get-changes error"
   rm $LOCKFILE
   exit 1
fi

if [ -f $MERGEDFILE ]
then
   # something left over from last time
   echo "merging with existing diff"
   if [ -f $BASE/data/osmium-mc.stderr ]; then
     mv $BASE/data/osmium-mc.stderr $BASE/data/osmium-mc.stderr.old
   fi
   if osmium merge-changes --no-progress -s -o $MERGEDFILE-new.osc $THISFILE $MERGEDFILE 2>$BASE/data/osmium-mc.stderr
   then
      mv $MERGEDFILE-new.osc $MERGEDFILE
   else
      >&2 echo "osmium mc error"
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
if osm2pgsql -G -a -d osm -U osm -s --number-processes=1 -C4000 -S $STYLE --flat-nodes $FLATNODEFILE -e $(($MINZOOM-3))-16 -o $EXPIRELOG --expire-bbox-size 20000 --hstore --tag-transform-script $LUA -p planet_osm_hstore $MERGEDFILE >$BASE/data/osm2pgsql.stdout 2>$BASE/data/osm2pgsql.stderr


then
   rm $MERGEDFILE
else
   >&2 echo "error in osm2pgsql"
   rm $LOCKFILE
   exit 1
fi

local_sequence=$(cat $SEQFILE)
LAG=$(expr $sequenceNumber - $local_sequence)
echo "end update;   osmosis replication is ${LAG} minutes behind upstream"

if [ -f $BASE/data/doexpire ]; then
  sort -u $EXPIRELOG >$EXPIRELOG.uniq
  mv $EXPIRELOG.uniq $EXPIRELOG
  explog=$(expiremeta.pl --map=mapnikde --minzoom=$MINZOOM <$EXPIRELOG)
  echo "expire: $explog"
  /usr/local/bin/expirehrb
  mv $EXPIRELOG $EXPIRELOG.old
  rm $BASE/data/doexpire
fi

rm $LOCKFILE
