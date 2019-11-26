#!/bin/bash

# set -x
STOP_CONT="no"

if [ "$#" -ne 1 ]; then
    echo "usage: <import|update|run>"
    echo "commands:"
    echo "    import: initial import of osm data"
    echo "    update: Set up the database and import /data.osm.pbf"
    echo "    run: just for debuigging"
    exit 1
fi

if [ "$1" = "import" ]; then
    exit 0
fi

if [ "$1" = "run" ]; then
    # add handler for signal SIHTERM
    trap 'sighandler_TERM' 15

    echo "wait for terminate signal"
    while [  "$STOP_CONT" = "no"  ] ; do
      sleep 1
    done

    exit 0
fi

echo "invalid command"
exit 1