#!/usr/bin/env bash
cd $(dirname $0)
W=$(pwd)
EP=/sbin/cops_entry_point.sh
docker run --cap-add SYS_PTRACE --cap-add SYS_ADMIN -e IMG_DEBUG=1 \
     -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
     -v $W/container_rootfs/$EP:$EP \
     corpusops/ubuntu:16.04 "$EP"
# vim:set et sts=4 ts=4 tw=80:
