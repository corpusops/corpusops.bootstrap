#!/usr/bin/env bash
envf="/root/vagrant/provision_settings.sh"
FORCE_INSTALL=${FORCE_INSTALL:-}
FORCE_SYNC=${FORCE_SYNC:-}
FIRST=${FIRST:-}
ORIG=${ORIG:-/host}
PREFIX=${PREFIX:-/srv/corpusops/corpusops.bootstrap}

log() {
    echo "[vagrant_provision] $@" >&2
}

vv() {
    log "${@}"
    "${@}"
}

may_die() {
    thetest=${1:-1}
    rc=${2:-1}
    shift
    shift
    if [ "x${thetest}" != "x0" ]; then
        log "FAILED: ${@}"
        exit $rc
    fi
}

die() {
    may_die 1 1 "${@}"
}

die_in_error_() {
    ret=${1}
    shift
    msg="${@:-"$ERROR_MSG"}"
    may_die "${ret}" "${ret}" "${msg}"
}

die_in_error() {
    die_in_error_ "${?}" "${@}"
}

. "$envf" || die "not in vagrant, no $envf"

if [ ! -e "$PREFIX" ];then mkdir -pv "$PREFIX";fi
cd "$PREFIX" || die "no $PREFIX"
if [ ! -e venv/bin/ansible ];then FORCE_INSTALL=1;fi
if [ ! -e "$PREFIX/roles/corpusops.vars" ] \
    ||  [ ! -e "$PREFIX/venv/src/ansible" ] \
    ||  [ ! -e "$PREFIX/playbooks/corpusops" ] \
    ||  [ ! -e "$PREFIX/venv/bin/ansible" ];then
    FIRST=y
    FORCE_SYNC=y
fi
if [[ -n ${FIRST} ]] || [ ! -e "$PREFIX/.git" ];then
    FORCE_INSTALL=y
    FORCE_SYNC=y
    FIRST=y      n
    if [ -e "$ORIG/.git" ];then
        vv rsync -az "$ORIG/" "$PREFIX/" \
            --exclude=venv \
            --exclude=roles \
            --exclude=playbooks
        die_in_error "rsync core"
    fi
fi
if [[ -n "${FIRST}" ]];then
    NONINTERACTIVE=y ./bin/cops_pkgmgr_install.sh git
    die_in_error "git install failed"
    cd $PREFIX \
        && git reset    -- playbooks roles \
        && git checkout -- playbooks roles
    die_in_error "fix git failed"
fi
if [ ! -e "$PREFIX/venv/src" ];then mkdir -p "$PREFIX/venv/src";fi
if  [[ -n ${FIRST} ]];then
    FORCE_SYNC=y
    for i in venv/src/ansible/ roles/ playbooks/;do
        if [ -e "${ORIG}/${i}" ];then
            vv rsync -az "$ORIG/${i}" "$PREFIX/${i}"
            die_in_error "rsync ${i}"
        fi
    done
fi
if [[ -n $FORCE_INSTALL ]];then
    vv bin/install.sh -C -S
    die_in_error "install core"
else
    log "Skip corpusops install"
fi
if [[ -n $FORCE_SYNC ]]; then
    vv bin/install.sh -C -s
    die_in_error "sync"
else
    log "Skip corpusops sync"
fi
# vim:set et sts=4 ts=4 tw=80:
