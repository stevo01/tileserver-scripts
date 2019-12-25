#!/bin/bash

# start and stops the osm tile server

set -x

IMAGE_NAME="osm-db-utils"

function start() {
docker run \
		--name $IMAGE_NAME \
		--rm=false \
		-e OSM2PGSQL_EXTRA_ARGS="--flat-nodes /nodes/flat_nodes.bin -C 4096" \
		--restart unless-stopped \
		--detach \
		--memory=32G \
		--hostname osmdbutils \
		--link osm-tileserver-db:osm-tileserver-db \
		-v openstreetmap-flat:/nodes \
		-v $PWD/volumes/transfer:/transfer \
		-v $PWD/volumes/work:/replication/work \
		-v $PWD/volumes/download:/replication/download \
		$IMAGE_NAME \
		run
}

function stop() {
  docker container stop $IMAGE_NAME
  docker container rm $IMAGE_NAME
}

function build() {
  docker build -t $IMAGE_NAME ./src
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    build
    stop
    start
    ;;
  build)
    build
	;;
  connect)
		docker exec -i -t $IMAGE_NAME /bin/bash
	;;
  log)
		docker logs -f $IMAGE_NAME
	;;
  *)
	echo "Usage: docker.service.sh {start|stop|restart|build|connect|import|log}" >&2
	exit 1
	;;
esac

exit 0
