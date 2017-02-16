#!/usr/bin/env bash
cd "$(dirname "$0")/../.."
. bin/cops_shell_common
if [ ! -e mountpoint ];then
    mkdir mountpoint
fi
hacking/vagrant/sshgen.sh &&\
vv sshfs -F "$(pwd)/sshconfig" vagrant:/ mountpoint
die_in_error "Error while mounting"
# vim:set et sts=4 ts=4 tw=80:
