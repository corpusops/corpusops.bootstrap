#!/usr/bin/env bash
cd $(dirname "$0")/..
sc=bin/cops_shell_common
[[ ! -e $sc ]] && echo "missing $sc" >&2
. $sc || exit 1
envf="/root/vagrant/provision_settings.sh"
FORCE_INSTALL=${FORCE_INSTALL:-}
FORCE_SYNC=${FORCE_SYNC:-}
PREFIX=${PREFIX:-/srv/corpusops/corpusops.bootstrap}

usage () {
    NO_HEADER=y die '
Provision a vagrant vm

    '"$0"'
'
}

parse_cli() {
    parse_cli_common "${@}"
}
parse_cli "$@"


. "$envf" || die "not in vagrant, no $envf"

[ ! -e "$PREFIX/venv/bin/ansible" ] && FORCE_INSTALL=1

if      [ ! -e "$PREFIX/roles/corpusops.vars" ] \
    ||  [ ! -e "$PREFIX/venv/src/ansible" ] \
    ||  [ ! -e "$PREFIX/playbooks/corpusops" ] \
    ||  [ ! -e "$PREFIX/venv/bin/ansible" ]; then
    FORCE_SYNC=y
fi

if [[ -n $FORCE_INSTALL ]]; then
    vv "$PREFIX/bin/install.sh" -C -S
    die_in_error "install core"
else
    log "Skip corpusops install"
fi

if [[ -n $FORCE_SYNC ]]; then
    vv "$PREFIX/bin/install.sh" -C -s
    die_in_error "sync"
else
    log "Skip corpusops sync"
fi
# vim:set et sts=4 ts=4 tw=80:
