#!/usr/bin/env bash
cd $(dirname $0)
W=$(pwd)
caps="--cap-add SYS_ADMIN"
caps="--cap-add SYS_PTRACE --cap-add SYS_ADMIN"
caps=""
EP=/entry_point
img=corpusops/ubuntu:16.04
img=corpusops/centos:7
set -x
docker run -t\
 $caps \
 -e IMG_DEBUG=${IMG_DEBUG-} \
 -e IMG_NOQUIET=${IMG_NOQUIET-1} \
 -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
 -v $W/container_rootfs/entry_point:/entry_point \
 -v $W/container_rootfs/sbin/cops_container_cleanup.sh:/sbin/cops_container_cleanup.sh \
 $img
# vim:set et sts=4 ts=4 tw=80:
