#!/usr/bin/env bash
cd "$(dirname "$0")/../.."
. bin/cops_shell_common
vagrant ssh-config | sed \
    -e "s/User .*/User root/g" \
    -e "s/Host .*/Host vagrant/g" > sshconfig
if ! ( grep -q "Host vagrant" sshconfig );then
    log "pb with vagrant-sshconfig"
    exit 1
fi
# vim:set et sts=4 ts=4 tw=80:
