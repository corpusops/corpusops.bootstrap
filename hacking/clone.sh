#!/usr/bin/env bash
cd $(dirname "$0")/..
sc=bin/cops_shell_common
[[ ! -e $sc ]] && echo "missing $sc" >&2
. $sc || exit 1
envf="/root/vagrant/provision_settings.sh"
FORCE_INSTALL=${FORCE_INSTALL:-}
FORCE_SYNC=${FORCE_SYNC:-}
CLONE_PATH=${CLONE_PATH:-${1}}

usage () {
    NO_HEADER=y die '
Clone a corpusops install to speed up reinstall

[CLONE_PATH=/path/to/newclonealtsetting]
    '"$0"' /path/to/newclone
'
}
parse_cli() {
    parse_cli_common "${@}"
    if [ -z $CLONE_PATH ];then
        die "no \$CLONE_PATH"
    fi
}
parse_cli "$@"
log "Cloning in ${CLONE_PATH}"
if [ ! -d "${CLONE_PATH}" ];then
    mkdir -pv "${CLONE_PATH}"
fi
if [ ! -d "${CLONE_PATH}" ];then
    die "$CLONE_PATH invalid"
fi

cd "$W"
vv rsync -a ./ "${CLONE_PATH}" \
    --exclude=sshconfig \
    --exclude=mountpoint \
    --exclude=*.box \
    --exclude=venv \
    --exclude=vagrant_config.yml \
    --exclude=.vagrant
if [ -e vagrant_config.yml ] && [ ! -e "${CLONE_PATH}/vagrant_config.yml" ];then
    vv cp -f vagrant_config.yml "${CLONE_PATH}"
fi
if [ ! -e "${CLONE_PATH}/venv/src" ];then
    vv mkdir -p "${CLONE_PATH}/venv/src"
fi
if [ -e venv/src ];then
    vv rsync -a venv/src/ "${CLONE_PATH}/venv/src/"
fi
log "Clone complete in ${CLONE_PATH}"
# vim:set et sts=4 ts=4 tw=80:
