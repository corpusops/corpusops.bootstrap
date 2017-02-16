#!/usr/bin/env bash
cd $(dirname $0)/../..
vagrant ssh-config | sed \
    -e "s/User .*/User root/g" \
    -e "s/Host .*/Host vagrant/g" > sshconfig
ssh -F sshconfig vagrant
# vim:set et sts=4 ts=4 tw=80:
