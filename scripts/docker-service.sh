#!/bin/bash

# start and stops the osm tile server

set -x

IMAGE_NAME="osm-db-utils"

function start() {
docker run \
		--name $IMAGE_NAME \
		--rm=false \
		--detach \
		--memory=32G \
		--hostname osmdbutils \
		--link osm-tileserver-db:osm-tileserver-db \
		-v openstreetmap-flat:/nodes \
		-v openstreetmap-db:/var/lib/postgresql/11/main:ro \
		-v $PWD/volumes/transfer:/transfer \
		-v $PWD/volumes/work:/replication/work \
		-v $PWD/volumes/download:/replication/download \
		-v $PWD/volumes/backup:/backup \
		$IMAGE_NAME \
		run
}

function import() {
docker run \
		--name $IMAGE_NAME \
		--rm=false \
		--detach \
		--memory=32G \
		--hostname osmdbutils \
		--link osm-tileserver-db:osm-tileserver-db \
		-v openstreetmap-flat:/nodes \
		-v $PWD/volumes/transfer:/transfer \
		-v $PWD/volumes/work:/replication/work \
		-v $PWD/volumes/download:/replication/download \
		$IMAGE_NAME \
		import
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
	import)
	    import
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
