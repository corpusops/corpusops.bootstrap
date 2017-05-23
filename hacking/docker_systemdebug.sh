#!/usr/bin/env bash
cd $(dirname $0)
W=$(pwd)
docker run --cap-add SYS_PTRACE --cap-add SYS_ADMIN -e IMG_DEBUG=1 \
     -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
     -v $W/container_rootfs/sbin/cops_systemd_entry_point.sh:/sbin/cops_systemd_entry_point.sh \
     corpusops/ubuntu:16.04 "/sbin/cops_systemd_entry_point.sh"
# vim:set et sts=4 ts=4 tw=80:
