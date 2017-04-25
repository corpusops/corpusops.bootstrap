#!/usr/bin/env bash

export LOGGER_NAME=cops_vagrant
sc=bin/cops_shell_common
[[ ! -e $sc ]] && echo "missing $sc" >&2
. $sc || exit 1

envf="/root/vagrant/provision_settings.sh"
. "$envf" || die "not in vagrant, no $envf"

FORCE_INSTALL=${FORCE_INSTALL:-}
FORCE_SYNC=${FORCE_SYNC:-}
ORIG=${ORIG:-/host}
PREFIX=${PREFIX:-/srv/corpusops/corpusops.bootstrap}

sync_ssh() {
    if [[ -n "${SKIP_ROOTSSHKEYS_SYNC}" ]];then
        log "Skip ssh keys sync to root user"
        return 0
    fi
    log "Synchronising user authorized_keys to root"
    if [ ! -e /root/.ssh ];then
        mkdir /root/.ssh
        chmod 700 /root/.ssh
    fi
    fics=""
    users="ubuntu vagrant"
    for u in ${users};do
        for i in $(ls /home/${u}/.ssh/authorized_key* 2>/dev/null);do
            fics="${fics} ${i}"
        done
    done
    if [ "x${fics}" != "x" ];then
        echo > /root/.ssh/authorized_keys
        for i in ${fics};do
            cat ${i} >> /root/.ssh/authorized_keys
            echo >> /root/.ssh/authorized_keys
        done
    fi
}

install_sync_() {
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
}

save_back_to_host() {
    if [[ -n "${SKIP_SENDBACKTOHOST}" ]];then
        log "Skip send back to host"
        return 0
    fi
    # to speed up if we "vagrant destroy", save the checkouted
    # stuff onto the host even if we do not use it in the
    # first place
    cd $PREFIX || die "$PREFIX does not exists"
    # HARMFUL !!!
    #vv rsync -az "$PREFIX/" "$ORIG/" \
    #    --exclude=hacking/vagrant \
    #    --exclude=venv \
    #    --exclude=roles \
    #    --exclude=playbooks
    #die_in_error "rsync core"
    for i in venv/src/ansible/ roles/ playbooks/;do
        if [ ! -e "${ORIG}/${i}" ];then
            mkdir -p "${ORIG}/${i}"
        fi
        vv rsync -az "$PREFIX/${i}" "$ORIG/${i}"
        die_in_error "rsync back ${i}"
    done
}

install_corpusops_copy() {
    if [[ -n "${SKIP_INSTALL}" ]];then
        log "Skip install"
        return 0
    fi
    if [ ! -e "$PREFIX" ];then
        mkdir -pv "$PREFIX"
    fi
    cd "${PREFIX}"
    FIRST=${FIRST:-}
    if [ ! -e .git ];then
        FIRST=y
        FORCE_INSTALL=y
        FORCE_SYNC=y
        if [ -e "$ORIG/.git" ];then
            vv rsync -az "$ORIG/" "$PREFIX/" \
                --exclude=.vagrant \
                --exclude=hacking/vagrant \
                --exclude=venv \
                --exclude=roles \
                --exclude=playbooks
            die_in_error "rsync core"
        fi
    fi
    if ! has_command git;then
        NONINTERACTIVE=y vv ./bin/cops_pkgmgr_install.sh git
        die_in_error "git install failed"
    fi
    if [ ! -e "$PREFIX/venv/src" ];then
        mkdir -p "$PREFIX/venv/src"
    fi
    if [ ! -e "$PREFIX/venv/bin/ansible" ]  ||\
        ! ( has_command virtualenv ) ;then
        FORCE_INSTALL=1
    fi
    if      [ ! -e "$PREFIX/roles/corpusops.roles" ] \
        ||  [ ! -e "$PREFIX/venv/src/ansible" ] \
        ||  [ ! -e "$PREFIX/playbooks/corpusops" ] \
        ||  [ ! -e "$PREFIX/venv/bin/ansible" ]; then
        FORCE_SYNC=y
    fi
    if [[ -n ${FIRST} ]];then
        git reset -- playbooks roles \
            && git checkout -- playbooks roles
        die_in_error "fix git failed"
        for i in venv/src/ansible/ roles/ playbooks/;do
            if [ -e "${ORIG}/${i}" ];then
                vv rsync -az "$ORIG/${i}" "$PREFIX/${i}"
                die_in_error "rsync ${i}"
            fi
        done
    fi
    install_sync_
    save_back_to_host
}

install_corpusops() {
    if [[ -n "${SKIP_INSTALL}" ]];then
        log "Skip install"
        return 0
    fi
    if [ ! -e "$PREFIX/venv/bin/ansible" ]  ||\
        ! ( has_command virtualenv ) ;then
        FORCE_INSTALL=1
    fi
    if      [ ! -e "$PREFIX/roles/corpusops.roles" ] \
        ||  [ ! -e "$PREFIX/venv/src/ansible" ] \
        ||  [ ! -e "$PREFIX/playbooks/corpusops" ] \
        ||  [ ! -e "$PREFIX/venv/bin/ansible" ]; then
        FORCE_SYNC=y
    fi
    install_sync_
}
# vim:set et sts=4 ts=4 tw=80:
