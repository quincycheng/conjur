#!/bin/bash -ex
export DEBIFY_IMAGE='registry.tld/conjurinc/debify:1.11.5.1-0251923'
docker pull registry.tld/cyberark/phusion-ruby-fips:0.11-d243f6c
docker run --rm $DEBIFY_IMAGE config script > docker-debify
chmod +x docker-debify

./docker-debify package \
  --dockerfile=Dockerfile.fpm \
  possum \
  -- \
  --depends tzdata
