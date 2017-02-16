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

[FORCE_SYNC] \
[FORCE_INSTALL] \
[SKIP_INSTALL] \
[SKIP_ROOTSSHKEYS_SYNC] \
    '"$0"'
'
}

parse_cli() {
    parse_cli_common "${@}"
}
parse_cli "$@"

. "$envf" || die "not in vagrant, no $envf"

sync_ssh() {
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

install_corpusops() {
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
}

echo "->$SKIP_ROOTSSHKEYS_SYNC<-"
if [[ -z "${SKIP_ROOTSSHKEYS_SYNC}" ]];then
	sync_ssh
else
    log "skip install_corpusops"
fi
if [[ -z "${SKIP_INSTALL}" ]];then
	install_corpusops
else
    log "skip install_corpusops"
fi
# vim:set et sts=4 ts=4 tw=80:
