#!/bin/bash

IMAGE_NAME="osm-db-utils"

docker run \
		--name $IMAGE_NAME \
		--rm=false \
		-e OSM2PGSQL_EXTRA_ARGS="--flat-nodes /nodes/flat_nodes.bin -C 4096" \
		--restart unless-stopped \
		--detach \
		--memory=32G \
		-v openstreetmap-flat-planet-latest:/nodes \
		-v $PWD/volumes/transfer:/transfer \
		-v $PWD/volumes/work:/replication/work \
		$IMAGE_NAME \
		run

exit 0
