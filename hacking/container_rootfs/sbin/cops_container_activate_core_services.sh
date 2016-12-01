#!/usr/bin/env bash
# activate a service without the process manager helpers
# we use generally this script when the process manager isn't up, so
# we can't use it !
set -ex
es=/etc/systemd/system
services="container-stop container-start"
if [ -e /lib/systemd/systemd ];then
    for s in $services;do
        case $s in
            container-start) t=sysinit;;
            container-stop) t=shutdow;;
            *) t=multi-users;;
        esac
        w="/etc/systemd/system/${t}.target.wants"
        if [ ! -e "${d}" ];then
            mkdir -pv "${w}"
        fi
        ln -vs "$es/$s.service" "${w}/$s.service"
    done
else
    if LC_ALL=C LANG=C /sbin/init --help 2>&1 | grep -iq upstart;then
        # verify that jobs are in place
        for i in $services;do
            j="/etc/init/${i}.conf"
            o="${j}.override"
            if [[ ! -e "${j}" ]];then
                echo "missing ${j}" >&2
                exit 1
            fi
            if [[ -e "${o}" ]];then
                rm -vf "${o}"
            fi
        done
    fi
fi
# vim:set et sts=4 ts=4 tw=80:
