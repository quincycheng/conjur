#!/bin/bash -ex

docker exec -i $(docker ps -aq) bash -c "/src/localrun/$1"
