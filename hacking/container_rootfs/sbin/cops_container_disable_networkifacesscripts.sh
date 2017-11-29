#!/usr/bin/env bash
set -ex

C=$(pwd)
if [[ -z ${NO_DISABLE_NETWORK_SCRIPTS-} ]];then
    : Remove any deb-like network scripts
    for i in if-down.d if-post-down.d if-pre-up.d if-up.d;do
     if [ -e /etc/network/$i ];then
      cd /etc/network/$i
      for j in *;do
        if [ -f $j ];then
            rm -f $j
            ln -sfv /bin/true $j
        fi
      done
     fi
    done
    cd "$C"
fi
# vim:set et sts=4 ts=4 tw=80:
