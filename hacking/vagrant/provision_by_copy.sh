#!/usr/bin/env bash
cd $(dirname "$0")/../..
. hacking/vagrant/common.sh || exit 1
usage () {
    NO_HEADER=y die '
Provision a vagrant vm

[PREFIX=] \
[FORCE_SYNC] \
[FORCE_INSTALL] \
[SKIP_INSTALL] \
[SKIP_SENDBACKTOHOST] \
[SKIP_ROOTSSHKEYS_SYNC] \
    '"$0"'
'
}
parse_cli() {
    parse_cli_common "${@}"
}
parse_cli "$@"
sync_ssh
install_corpusops_copy
# vim:set et sts=4 ts=4 tw=80:
