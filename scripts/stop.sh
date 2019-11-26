#!/bin/bash

IMAGE_NAME="osm-db-utils"

docker container stop $IMAGE_NAME
docker container rm $IMAGE_NAME
