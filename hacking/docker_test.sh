#!/usr/bin/env bash
set -ex
TAG=${TAG:-image}
DOCKERFILE=${DOCKERFILE:-Dockerfile}
WD=${WD-$(pwd)}
docker build --squash -t $TAG $WD -f $DOCKERFILE $@
# vim:set et sts=4 ts=4 tw=80:
