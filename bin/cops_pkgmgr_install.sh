#!/usr/bin/env bash
cd "$(dirname ${0})"
W=$(cd .. && pwd)
LOGGER_NAME=pkgmgr

sc=cops_shell_common
[[ ! -e $sc ]] && echo "missing $sc" >&2
. $sc || exit 1

detect_os

usage() {
    echo '
Universal shell wrapper to manage OS package manager
OS SUPPORT: debian / archlnux / redhat

[WANTED_EXTRA_PACKAGES="vim"] \
[WANTED_EXTRA_PACKAGES="nano"] \
[DO_UPGRADE=y] [SKIP_UPGRADE=y] \
[DO_UPGRADE=y] [SKIP_UPGRADE=y] \
[DO_INSTALL=y] [SKIP_INSTALL=y] \
[DEBUG=y"] \
    '"${0}"' [--help] [packagea] [packageb]'
}

APT_CONF_FILE="/etc/apt/apt.conf.d/01buildconfig"
REQS_PATH="/srv/corpusops.bootstrap/requirements"
WANTED_EXTRA_PACKAGES=${WANTED_EXTRA_PACKAGES-}
WANTED_PACKAGES=${WANTED_PACKAGES-}
for i in ${@-};do
    case $i in
        --help|-h) :;;
        *) WANTED_PACKAGES="${WANTED_PACKAGES} ${i}";;
    esac
done
NONINTERACTIVE=${NONINTERACTIVE-}
SKIP_INSTALL=${SKIP_INSTALL-}
SKIP_UPDATE=${SKIP_UPDATE-}
SKIP_UPGRADE=${SKIP_UPGRADE-}
DO_UPGRADE=${DO_UPGRADE-}
DO_UPDATE=${DO_UPDATE-default}
DO_INSTALL=${DO_INSTALL-default}
container=${container-}

WANTED_PACKAGES="$(echo "$(echo "${WANTED_PACKAGES}" | xargs -n1 | sort -u)")"
WANTED_EXTRA_PACKAGES="$(echo "$(echo "${WANTED_EXTRA_PACKAGES}" | xargs -n1 | sort -u)")"

###
is_pacman_available() {
    if ! apt-cache show ${@} >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

is_pacman_installed() {
    if ! dpkg-query -s ${@} 2>/dev/null|egrep "^Status:"|grep -q installed; then
        return 1
    fi
}

pacman_update() {
    return 1
}

pacman_upgrade() {
    return 1
}

pacman_install() {
    return 1
    vvv pacman install $@
}

###
is_dnf_available() {
    if ! apt-cache show ${@} >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

is_dnf_installed() {
    if ! dpkg-query -s ${@} 2>/dev/null|egrep "^Status:"|grep -q installed; then
        return 1
    fi
}

dnf_update() {
    return 1
}

dnf_upgrade() {
    return 1
}

dnf_install() {
    return 1
    vvv dnf install $@
}

###
is_yum_available() {
    if ! apt-cache show ${@} >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

is_yum_installed() {
    if ! dpkg-query -s ${@} 2>/dev/null|egrep "^Status:"|grep -q installed; then
        return 1
    fi
}

yum_update() {
    return 1
}

yum_upgrade() {
    return 1
}

yum_install() {
    return 1
    vvv yum install $@
}

###
is_aptget_available() {
    if ! apt-cache show ${@} >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

is_aptget_installed() {
    if ! dpkg-query -s ${@} 2>/dev/null|egrep "^Status:"|grep -q installed; then
        return 1
    fi
}

aptget_add_conf() {
    if [[ -n "$2" ]] && grep -q "$2" $APT_CONF_FILE 2>/dev/null;then
        log "test $2 success, skip adding slug $1"
    else
        echo "${1}" >> $APT_CONF_FILE
    fi
}

aptget_update() {
    vvv apt-get update
}

aptget_upgrade() {
    vvv apt-get dist-upgrade
}

aptget_install() {
    vvv apt-get install ${@}
}

parse_cli "${@}"

if [ "x${DEBIAN_FRONTEND-}" = "noninteractive" ] \
    || [ "x${container-}" = "xdocker" ];then
    NONINTERACTIVE=y
fi

if echo ${DISTRIB_ID} | egrep -iq "ubuntu|debian";then
    if [[ -n "${NONINTERACTIVE}" ]];then
    	export DEBIAN_FRONTEND=noninteractive
        aptget_add_conf "APT::Install-Recommends "0";" "APT::Install-Recommends"
        aptget_add_conf "APT::Get::Assume-Yes "true";" "APT::Get::Assume-Yes"
        aptget_add_conf "APT::Get::force-yes "true";"  "APT::Get::force-yes"
        aptget_add_conf "APT::Install-Suggests "0";"   "APT::Install-Suggests"
    fi
    INSTALLER=aptget
elif echo ${DISTRIB_ID} | egrep -iq "archlinux";then
    INSTALLER=pacman
elif echo ${DISTRIB_ID} | egrep -iq "redhat|red-hat|centos|fedora";then
    INSTALLER=yum
    if hash -r dnf >/dev/null 2>&1;then
        INSTALLER=dnf
    fi
fi

if [[ -z "${SKIP_INSTALL}" ]];then
    if [[ -n "${WANTED_PACKAGES}" ]]; then
        for i in $WANTED_PACKAGES;do
            if ! is_${INSTALLER}_installed $i;then
                candidates="${candidates} ${i}"
            fi
        done
    fi
    if [[ -n "${WANTED_EXTRA_PACKAGES}" ]]; then
        for i in $WANTED_EXTRA_PACKAGES;do
            if ! is_${INSTALLER}_installed ${i} \
                && is_${INSTALLER}_available ${i};then
                candidates="${candidates} ${i}"
            fi
        done
    fi
    if [[ -z "${candidates}" ]];then
        if [ "x${DO_UPDATE}" = "xdefault" ];then
            DO_UPDATE=""
        fi
    fi
fi
if [[ -z "${SKIP_UPDATE}" ]] && [[ -n "${DO_UPDATE}" ]];then
    log ${INSTALLER}_update
    ${INSTALLER}_update
    may_die $? $? "update failed"
else
    debug "Skip update"
fi
if [[ -z "${SKIP_INSTALL}" ]];then
    if [[ -n "${WANTED_EXTRA_PACKAGES}" ]]; then
        for i in $WANTED_EXTRA_PACKAGES;do
            if ! is_${INSTALLER}_installed ${i} \
                && is_${INSTALLER}_available ${i};then
                candidates="${candidates} ${i}"
            fi
        done
    fi
fi
candidates=$( echo "${candidates}" | xargs -n1 | sort -u )
if [[ -n "${candidates}" ]]; then
    debug will install ${candidates}
fi
if [[ -z "${SKIP_UPGRADE}" ]] &&  [[ -n "${DO_UPGRADE}" ]];then
    log ${INSTALLER}_upgrade
    ${INSTALLER}_upgrade
    may_die $? $? "upgrade failed"
else
    debug "Skip upgrade"
fi
if [[ -z "${SKIP_INSTALL}" ]] \
    && [[ -n "${DO_INSTALL}" ]] \
    && [[ -n "${candidates}" ]]; then
    log ${INSTALLER}_install ${candidates}
    ${INSTALLER}_install ${candidates}
    may_die $? $? "install failed"
else
    debug "Skip install"
fi
# vim:set et sts=4 ts=4 tw=80:
