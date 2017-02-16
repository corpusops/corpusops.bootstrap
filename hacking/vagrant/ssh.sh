#!/usr/bin/env bash
cd "$(dirname "$0")/../.."
hacking/vagrant/sshgen.sh &&\
ssh -F sshconfig vagrant "${@}"
# vim:set et sts=4 ts=4 tw=80:
