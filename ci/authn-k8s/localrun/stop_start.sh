#!/bin/bash -x

docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

#./build.sh

# the first run will might gets fail on leftover from previous run
cd ci/authn-k8s && summon ./test.sh gke

