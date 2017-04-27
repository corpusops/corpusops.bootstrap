#!/usr/bin/env bash
set -ex
W=${COPS_ROOT:-/srv/corpusops/corpusops.bootstrap}
R=$W/hacking/container_rootfs
if [[ -n ${CORPUSOPS_IN_DEV} ]];then
    if [ -e "${R}" ];then
        rsync -av $R/ /
    fi
fi
if [ -e /sbin/init ] && \
    ( /sbin/init --version 2>&1 | grep -iq upstart; ) ;then
    exec /sbin/upstart
else
    exec /lib/systemd/systemd --system
fi
# vim:set et sts=4 ts=4 tw=80:
