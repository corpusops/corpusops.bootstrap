#!/usr/bin/env bash
shopt -s extglob

COPS_VAGRANT_DIR=${COPS_VAGRANT_DIR:-$(dirname "$(readlink -f "$0")")}
W=${W:-$(readlink -f "$COPS_VAGRANT_DIR/../..")}

sourcefile() {
    for i in $@;do
        . "$i"
        if [[ $? != 0 ]];then
            echo "$i sourcing failed"
            exit 1
        fi
    done
}

if [ -e .vagrant/provision_settings.sh ];then
    sourcefile .vagrant/provision_settings.sh
fi
if [ -e /root/vagrant/provision_settings.sh ];then
    sourcefile /root/vagrant/provision_settings.sh
fi

RED="\\e[0;31m"
CYAN="\\e[0;36m"
YELLOW="\\e[0;33m"
NORMAL="\\e[0;0m"
NO_COLOR=${NO_COLORS-${NO_COLORS-${NOCOLOR-${NOCOLORS-}}}}
LOGGER_NAME=${LOGGER_NAME:-cops_vagrant}


DEFAULT_COPS_SSHFS_OPTS="-o cache=yes -o kernel_cache"
DEFAULT_COPS_SSHFS_OPTS="$DEFAULT_COPS_SSHFS_OPTS -o large_read"
DEFAULT_COPS_SSHFS_OPTS="$DEFAULT_COPS_SSHFS_OPTS -o Ciphers=arcfour"
DEFAULT_COPS_SSHFS_OPTS="$DEFAULT_COPS_SSHFS_OPTS -o Compression=no"
DEFAULT_COPS_SSHFS_OPTS="$DEFAULT_COPS_SSHFS_OPTS -o ServerAliveCountMax=3 -o ServerAliveInterval=15"
DEFAULT_COPS_SSHFS_OPTS="$DEFAULT_COPS_SSHFS_OPTS -o reconnect"
DEFAULT_COPS_SSHFS_OPTS="$DEFAULT_COPS_SSHFS_OPTS -C -o workaround=all"
COPS_SSHFS_OPTS="${COPS_SSHFS_OPTS:-"$DEFAULT_COPS_SSHFS_OPTS"}"
DEFAULT_COPS_ROOT="/srv/corpusops/corpusops.bootstrap"
DEFAULT_COPS_URL="https://github.com/corpusops/corpusops.bootstrap.git"
COPS_URL=${COPS_URL-$DEFAULT_COPS_URL}
COPS_ROOT=${COPS_ROOT:-$W/local/corpusops.bootstrap}
HOST_MOUNTPOINT=${COPS_HOST_MOUNTPOINT:-/host}
HOST_COPS=${COPS_HOST_COPS:-$HOST_COPS/local/corpusops.bootstrap}
VMS_MOUNT_PATH=${VMS_MOUNT_PATH:-$W/local/mountpoint}

usage() {
    die 128 "No usage found"
}

parse_cli_common() {
    USAGE=
    for i in ${@-};do
        case ${i} in
            --no-color|--no-colors|--nocolor|--no-colors)
                NO_COLOR=1;;
            -h|--help)
                USAGE=1;;
            *) :;;
        esac
    done
    reset_colors
    if [[ -n ${USAGE} ]]; then
        usage
    fi
}

parse_cli() {
    parse_cli_common "${@}"
}

has_command() {
    ret=1
    if which which >/dev/null 2>/dev/null;then
      if which "${@}" >/dev/null 2>/dev/null;then
        ret=0
      fi
    else
      if command -v "${@}" >/dev/null 2>/dev/null;then
        ret=0
      else
        if hash -r "${@}" >/dev/null 2>/dev/null;then
            ret=0
        fi
      fi
    fi
    return ${ret}
}

get_command() {
    local p=
    local cmd="${@}"
    if which which >/dev/null 2>/dev/null;then
        p=$(which "${cmd}" 2>/dev/null)
    fi
    if [ "x${p}" = "x" ];then
        p=$(export IFS=:;
            echo "${PATH-}" | while read -ra pathea;do
                for pathe in "${pathea[@]}";do
                    pc="${pathe}/${cmd}";
                    if [ -x "${pc}" ]; then
                        p="${pc}"
                    fi
                done
                if [ "x${p}" != "x" ]; then echo "${p}";break;fi
            done )
    fi
    if [ "x${p}" != "x" ];then
        echo "${p}"
    fi
}

get_random_slug() {
    len=${1:-32}
    strings=${2:-'a-zA-Z0-9'}
    echo "$(cat /dev/urandom \
        | tr -dc "$strings" \
        | fold -w ${len} \
        | head -n 1)"
}

reset_colors() {
    if [[ -n ${NO_COLOR} ]]; then
        BLUE=""
        YELLOW=""
        RED=""
        CYAN=""
    fi
}

log_() {
    reset_colors
    logger_color=${1:-${RED}}
    msg_color=${2:-${YELLOW}}
    shift;shift;
    logger_slug="${logger_color}[${LOGGER_NAME}]${NORMAL} "
    if [[ -n ${NO_LOGGER_SLUG} ]];then
        logger_slug=""
    fi
    printf "${logger_slug}${msg_color}$(echo "${@}")${NORMAL}\n" >&2;
    printf "" >&2;  # flush
}

log() {
    log_ "${RED}" "${CYAN}" "${@}"
}

warn() {
    log_ "${RED}" "${CYAN}" "${YELLOW}[WARN] ${@}${NORMAL}"
}

may_die() {
    reset_colors
    thetest=${1:-1}
    rc=${2:-1}
    shift
    shift
    if [ "x${thetest}" != "x0" ]; then
        if [[ -z "${NO_HEADER-}" ]]; then
            NO_LOGGER_SLUG=y log_ "" "${CYAN}" "Problem detected:"
        fi
        NO_LOGGER_SLUG=y log_ "${RED}" "${RED}" "$@"
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

debug() {
    if [[ -n "${DEBUG// }" ]];then
        log_ "${YELLOW}" "${YELLOW}" "${@}"
    fi
}

vvv() {
    debug "${@}"
    "${@}"
}

vv() {
    log "${@}"
    "${@}"
}

is_archlinux_like() {
    echo $DISTRIB_ID | egrep -iq "archlinux"
}

is_debian_like() {
    echo $DISTRIB_ID | egrep -iq "debian|ubuntu|mint"
}

is_redhat_like() {
    echo $DISTRIB_ID | egrep -iq "fedora|centos|redhat|red-hat"
}

get_git_changeset() {
   ( cd "${1:-$(pwd)}" &&\
     git log HEAD|head -n1|awk '{print $2}')
}

get_git_branch() {
   ( cd "${1:-$(pwd)}" &&\
     git rev-parse --abbrev-ref HEAD | grep -v HEAD || \
     git describe --exact-match HEAD 2> /dev/null || \
     git rev-parse HEAD)
}

get_git_branchs() {
   ( cd "${1:-$(pwd)}" &&\
       git branch|sed -e "s/^\*\? \+//g")
}

version_lte() {
    [  "$1" = "$(printf "$1\n$2" | sort -V | head -n1)" ]
}

version_lt() {
    [ "$1" = "$2" ] && return 1 || version_lte $1 $2
}

version_gte() {
    [  "$2" = "$(printf "$1\n$2" | sort -V | head -n1)" ]
}

version_gt() {
    [ "$1" = "$2" ] && return 1 || version_gte $1 $2
}
# vim:set et sts=4 ts=4 tw=80:
