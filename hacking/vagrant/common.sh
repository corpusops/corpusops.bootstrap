#!/usr/bin/env bash
readlinkf() {
    if ( uname | egrep -iq "linux|darwin|bsd" );then
        if ( which greadlink 2>&1 >/dev/null );then
            greadlink -f "$@"
        elif ( which perl 2>&1 >/dev/null );then
            perl -MCwd -le 'print Cwd::abs_path shift' "$@"
        elif ( which python 2>&1 >/dev/null );then
            python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$@"
        fi
    else
        readlink -f "$@"
    fi
}
shopt -s extglob

COPS_VAGRANT_DIR=${COPS_VAGRANT_DIR:-$(dirname "$(readlinkf "$0")")}
W=${W:-$(readlinkf "$COPS_VAGRANT_DIR/../..")}

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

# BEGIN: corpusops common glue
readlinkf() {
    if ( uname | egrep -iq "darwin|bsd" );then
        if ( which greadlink 2>&1 >/dev/null );then
            greadlink -f "$@"
        elif ( which perl 2>&1 >/dev/null );then
            perl -MCwd -le 'print Cwd::abs_path shift' "$@"
        elif ( which python 2>&1 >/dev/null );then
            python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$@"
        fi
    else
        val="$(readlink -f "$@")"
        if [[ -z "$val" ]];then
            val=$(readlink "$@")
        fi
        echo "$val"
    fi
}
# scripts vars
SCRIPT=$0
LOGGER_NAME=${LOGGER_NAME-$(basename $0)}
SCRIPT_NAME=$(basename "${SCRIPT}")
SCRIPT_DIR=$(cd "$(dirname $0)" && pwd)
SCRIPT_ROOT=${SCRIPT_ROOT:-$(dirname $SCRIPT_DIR)}
# OW: from where script was called (must be defined from callee)
OW="${OW:-$(pwd)}"
# W is script_dir/..
W=${OVERRIDEN_W:-$(cd "$SCRIPT_DIR/.." && pwd)}
#
#
DEFAULT_COPS_ROOT="/srv/corpusops/corpusops.bootstrap"
DEFAULT_COPS_URL="https://github.com/corpusops/corpusops.bootstrap"
#
SYSTEM_COPS_ROOT=${SYSTEM_COPS_ROOT-$DEFAULT_COPS_ROOT}
DOCKER_COPS_ROOT=${DOCKER_COPS_ROOT-$SYSTEM_COPS_ROOT}
COPS_URL=${COPS_URL-$DEFAULT_COPS_URL}
BASE_PREPROVISION_IMAGES="ubuntu:latest_preprovision"
BASE_PREPROVISION_IMAGES="$BASE_PREPROVISION_IMAGES corpusops/ubuntu:18.04_preprovision"
BASE_PREPROVISION_IMAGES="$BASE_PREPROVISION_IMAGES corpusops/ubuntu:16.04_preprovision"
BASE_PREPROVISION_IMAGES="$BASE_PREPROVISION_IMAGES corpusops/ubuntu:14.04_preprovision"
BASE_PREPROVISION_IMAGES="$BASE_PREPROVISION_IMAGES corpusops/centos:7_preprovision"
BASE_CORE_IMAGES="$BASE_CORE_IMAGES corpusops/ubuntu:latest"

BASE_CORE_IMAGES="$BASE_CORE_IMAGES corpusops/ubuntu:latest"
BASE_CORE_IMAGES="$BASE_CORE_IMAGES corpusops/ubuntu:18.04"
BASE_CORE_IMAGES="$BASE_CORE_IMAGES corpusops/ubuntu:16.04"
BASE_CORE_IMAGES="$BASE_CORE_IMAGES corpusops/ubuntu:14.04"
BASE_CORE_IMAGES="$BASE_CORE_IMAGES corpusops/centos:7"
BASE_IMAGES="$BASE_PREPROVISION_IMAGES $BASE_CORE_IMAGES"
EXP_PREPROVISION_IMAGES=""
EXP_PREPROVISION_IMAGES="$EXP_PREPROVISION_IMAGES archlinux:latest_preprovision"
EXP_PREPROVISION_IMAGES="$EXP_PREPROVISION_IMAGES debian:latest_preprovision"
EXP_PREPROVISION_IMAGES="$EXP_PREPROVISION_IMAGES debian:stretch_preprovision"
EXP_PREPROVISION_IMAGES="$EXP_PREPROVISION_IMAGES debian:jessie_preprovision"
EXP_CORE_IMAGES=""
EXP_CORE_IMAGES="$EXP_CORE_IMAGES corpusops/archlinux:latest"
EXP_CORE_IMAGES="$EXP_CORE_IMAGES corpusops/debian:latest"
EXP_CORE_IMAGES="$EXP_CORE_IMAGES corpusops/debian:stretch"
EXP_CORE_IMAGES="$EXP_CORE_IMAGES corpusops/debian:jessie"
EXP_IMAGES="$EXP_PREPROVISION_IMAGES $EXP_CORE_IMAGES"
# ansible related
export DISABLE_MITOGEN=${DISABLE_MITOGEN-1}
#
# colors
RED="\\e[0;31m"
CYAN="\\e[0;36m"
YELLOW="\\e[0;33m"
NORMAL="\\e[0;0m"
NO_COLOR=${NO_COLORS-${NO_COLORS-${NOCOLOR-${NOCOLORS-}}}}
LOGGER_NAME=${LOGGER_NAME:-corpusops_build}
ERROR_MSG="There were errors"
uniquify_string() {
    local pattern=$1
    shift
    echo "$@" \
        | sed -e "s/${pattern}/\n/g" \
        | awk '!seen[$0]++' \
        | tr "\n" "${pattern}" \
        | sed -e "s/^${pattern}\|${pattern}$//g"
}
do_trap_() { rc=$?;func=$1;sig=$2;${func};if [ "x${sig}" != "xEXIT" ];then kill -${sig} $$;fi;exit $rc; }
do_trap() { rc=${?};func=${1};shift;sigs=${@};for sig in ${sigs};do trap "do_trap_ ${func} ${sig}" "${sig}";done; }
is_ci() { return $( set +e;( [ "x${TRAVIS-}" != "x" ] || [ "x${GITLAB_CI}" != "x" ] );echo $?; ); }
log_() {
    reset_colors;msg_color=${2:-${YELLOW}};
    logger_color=${1:-${RED}};
    logger_slug="${logger_color}[${LOGGER_NAME}]${NORMAL} ";
    shift;shift;
    if [ "x${NO_LOGGER_SLUG}" != "x" ];then logger_slug="";fi
    printf "${logger_slug}${msg_color}$(echo "${@}")${NORMAL}\n" >&2;
    printf "" >&2;  # flush
}
reset_colors() { if [ "x${NO_COLOR}" != "x" ];then BLUE="";YELLOW="";RED="";CYAN="";fi; }
log() { log_ "${RED}" "${CYAN}" "${@}"; }
get_chrono() { date "+%F_%H-%M-%S"; }
cronolog() { log_ "${RED}" "${CYAN}" "($(get_chrono)) ${@}"; }
debug() { if [ "x${DEBUG-}" != "x" ];then log_ "${YELLOW}" "${YELLOW}" "${@}"; fi; }
warn() { log_ "${RED}" "${CYAN}" "${YELLOW}[WARN] ${@}${NORMAL}"; }
bs_log(){ log_ "${RED}" "${YELLOW}" "${@}"; }
bs_yellow_log(){ log_ "${YELLOW}" "${YELLOW}" "${@}"; }
may_die() {
    reset_colors
    thetest=${1:-1}
    rc=${2:-1}
    shift
    shift
    if [ "x${thetest}" != "x0" ]; then
        if [ "x${NO_HEADER-}" = "x" ]; then
            NO_LOGGER_SLUG=y log_ "" "${CYAN}" "Problem detected:"
        fi
        NO_LOGGER_SLUG=y log_ "${RED}" "${RED}" "$@"
        exit $rc
    fi
}
die() { may_die 1 1 "${@}"; }
die_in_error_() {
    ret=${1}; shift; msg="${@:-"$ERROR_MSG"}";may_die "${ret}" "${ret}" "${msg}";
}
die_in_error() { die_in_error_ "${?}" "${@}"; }
die_() { NO_HEADER=y die_in_error_ $@; }
sdie() { NO_HEADER=y die $@; }
parse_cli() { parse_cli_common "${@}"; }
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
    if [ "x${USAGE}" != "x" ]; then
        usage
    fi
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
pipe_return() {
    local filter=$1;shift;local command=$@;
    (((($command; echo $? >&3) | $filter >&4) 3>&1) | (read xs; exit $xs)) 4>&1;
}
output_in_error() { ( do_trap output_in_error_post EXIT TERM QUIT INT;\
                      output_in_error_ "${@}" ; ); }
output_in_error_() {
    if [ "x${OUTPUT_IN_ERROR_DEBUG-}" != "x" ];then set -x;fi
    if ( is_ci );then
        DEFAULT_CI_BUILD=y
    fi
    CI_BUILD="${CI_BUILD-${DEFAULT_CI_BUILD-}}"
    if [ "x$CI_BUILD" != "x" ];then
        DEFAULT_NO_OUTPUT=y
        DEFAULT_DO_OUTPUT_TIMER=y
    fi
    VERBOSE="${VERBOSE-}"
    TIMER_FREQUENCE="${TIMER_FREQUENCE:-120}"
    NO_OUTPUT="${NO_OUTPUT-${DEFAULT_NO_OUTPUT-1}}"
    DO_OUTPUT_TIMER="${DO_OUTPUT_TIMER-$DEFAULT_DO_OUTPUT_TIMER}"
    LOG=${LOG-}
    if [ "x$NO_OUTPUT" != "x" ];then
        if [  "x${LOG}" = "x" ];then
            LOG=$(mktemp)
            DEFAULT_CLEANUP_LOG=y
        else
            DEFAULT_CLEANUP_LOG=
        fi
    else
        DEFAULT_CLEANUP_LOG=
    fi
    CLEANUP_LOG=${CLEANUP_LOG:-${DEFAULT_CLEANUP_LOG}}
    if [ "x$VERBOSE" != "x" ];then
        log "Running$([ "x$LOG" != "x" ] && echo "($LOG)"; ): $@";
    fi
    TMPTIMER=
    if [ "x${DO_OUTPUT_TIMER}" != "x" ]; then
        TMPTIMER=$(mktemp)
        ( i=0;\
          while test -f $TMPTIMER;do\
           i=$((++i));\
           if [ `expr $i % $TIMER_FREQUENCE` -eq 0 ];then \
               log "BuildInProgress$( if [ "x$LOG" != "x" ];then echo "($LOG)";fi ): ${@}";\
             i=0;\
           fi;\
           sleep 1;\
          done;\
          if [ "x$VERBOSE" != "x" ];then log "done: ${@}";fi; ) &
    fi
    # unset NO_OUTPUT= LOG= to prevent output_in_error children to be silent
    # at first
    reset_env="NO_OUTPUT LOG"
    if [ "x$NO_OUTPUT" != "x" ];then
        ( unset $reset_env;"${@}" ) >>"$LOG" 2>&1;ret=$?
    else
        if [ "x$LOG" != "x" ] && has_command tee;then
            ( unset $reset_env; pipe_return "tee -a $tlog" "${@}"; )
            ret=$?
        else
            ( unset $reset_env; "${@}"; )
            ret=$?
        fi
    fi
    if [ -e "$TMPTIMER" ]; then rm -f "${TMPTIMER}";fi
    if [ "x${OUTPUT_IN_ERROR_NO_WAIT-}" = "x" ];then wait;fi
    if [ -e "$LOG" ] &&  [ "x${ret}" != "x0" ] && [ "x$NO_OUTPUT" != "x" ];then
        cat "$LOG" >&2
    fi
    if [ "x${OUTPUT_IN_ERROR_DEBUG-}" != "x" ];then set +x;fi
    return ${ret}
}
output_in_error_post() {
    if [ -e "$TMPTIMER" ]; then rm -f "${TMPTIMER}";fi
    if [ -e "$LOG" ] && [ "x$CLEANUP_LOG" != "x" ];then rm -f "$LOG";fi
}
test_silent_log() { ( [ "x${NO_SILENT-}" = "x" ] && ( [ "x${SILENT_LOG-}" != "x" ] || [ x"${SILENT_DEBUG}" != "x" ] ) ); }
test_silent() { ( [ "x${NO_SILENT-}" = "x" ] && ( [ "x${SILENT-}" != "x" ] || test_silent_log ) ); }
silent_run_() {
    (LOG=${SILENT_LOG:-${LOG}};
     NO_OUTPUT=${NO_OUTPUT-};\
     if test_silent;then NO_OUTPUT=y;fi;output_in_error "$@";)
}
silent_run() { ( silent_run_ "${@}" ; ); }
run_silent() {
    (
    DEFAULT_RUN_SILENT=1;
    if [ "x${NO_SILENT-}" != "x" ];then DEFAULT_RUN_SILENT=;fi;
    SILENT=${SILENT-DEFAULT_RUN_SILENT} silent_run "${@}";
    )
}
vvv() { debug "${@}";silent_run "${@}"; }
vv() { log "${@}";silent_run "${@}"; }
silent_vv() { SILENT=${SILENT-1} vv "${@}"; }
quiet_vv() { if [ "x${QUIET-}" = "x" ];then log "${@}";fi;run_silent "${@}";}
version_lte() { [  "$1" = "$(printf "$1\n$2" | sort -V | head -n1)" ]; }
version_lt() { [ "$1" = "$2" ] && return 1 || version_lte $1 $2; }
version_gte() { [  "$2" = "$(printf "$1\n$2" | sort -V | head -n1)" ]; }
version_gt() { [ "$1" = "$2" ] && return 1 || version_gte $1 $2; }
is_archlinux_like() { echo $DISTRIB_ID | egrep -iq "archlinux|arch"; }
is_debian_like() { echo $DISTRIB_ID | egrep -iq "debian|ubuntu|mint"; }
is_suse_like() { echo $DISTRIB_ID | egrep -iq "suse"; }
is_alpine_like() { echo $DISTRIB_ID | egrep -iq "alpine" || test -e /etc/alpine-release; }
is_redhat_like() { echo $DISTRIB_ID \
        | egrep -iq "((^ol$)|rhel|redhat|red-hat|centos|fedora)"; }
set_lang() { locale=${1:-C};export LANG=${locale};export LC_ALL=${locale}; }
detect_os() {
    # this function should be copiable in other scripts, dont use adjacent functions
    UNAME="${UNAME:-"$(uname | awk '{print tolower($1)}')"}"
    PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
    SED="sed"
    if [ "x${UNAME}" != "xlinux" ] && hash -r gsed >/dev/null 2>&1; then
        SED=gsed
    fi
    DISTRIB_CODENAME=""
    DISTRIB_ID=""
    DISTRIB_RELEASE=""
    if ( lsb_release -h >/dev/null 2>&1 ); then
        DISTRIB_ID=$(lsb_release -si)
        DISTRIB_CODENAME=$(lsb_release -sc)
        DISTRIB_RELEASE=$(lsb_release -sr)
    elif [ -e /etc/lsb-release ];then
        debug "No lsb_release, sourcing manually /etc/lsb-release"
        DISTRIB_ID=$(. /etc/lsb-release;echo ${DISTRIB_ID})
        DISTRIB_CODENAME=$(. /etc/lsb-release;echo ${DISTRIB_CODENAME})
        DISTRIB_RELEASE=$(. /etc/lsb-release;echo ${DISTRIB_RELEASE})
    elif [ -e /etc/os-release ];then
        DISTRIB_ID=$(. /etc/os-release;echo $ID)
        DISTRIB_CODENAME=$(. /etc/os-release;echo $VERSION)
        DISTRIB_CODENAME=$(echo $DISTRIB_CODENAME |sed -e "s/.*(\([^)]\+\))/\1/")
        DISTRIB_RELEASE=$(. /etc/os-release;echo $VERSION_ID)
    elif [ -e /etc/alpine-release ];then
        DISTRIB_ID="alpine"
        DISTRIB_CODENAME="Alpine Linux"
        DISTRIB_RELEASE="$(cat /etc/alpine-release)"
    elif [ -e /etc/debian_version ];then
        DISTRIB_ID="Debian"
        DISTRIB_RELEASE="$(cat /etc/debian_version)"
        DISTRIB_MAJOR=$(echo $DISTRIB_RELEASE |cut -d. -f 1)
        if [ $DISTRIB_MAJOR  -eq 6 ];then DISTRIB_CODENAME="squeeze";fi
        if [ $DISTRIB_MAJOR  -eq 7 ];then DISTRIB_CODENAME="wheezy";fi
        if [ $DISTRIB_MAJOR  -eq 8 ];then DISTRIB_CODENAME="jessie";fi
        if [ $DISTRIB_MAJOR  -eq 9 ];then DISTRIB_CODENAME="stretch";fi
    elif [ -e /etc/SuSE-brand ] || [ -e /etc/SuSE-release ];then
        for i in /etc/SuSE-brand /etc/SuSE-release;do
            if [ -e $i ];then
                DISTRIB_CODENAME="$(head -n 1 $i)"
                DISTRIB_ID="openSUSE project"
                DISTRIB_RELEASE="$(grep VERSION $i |awk '{print $3}')"
                break
            fi
        done
    elif [ -e /etc/redhat-release ];then
        RHRELEASE=$(cat /etc/redhat-release)
        DISTRIB_CODENAME=${RHRELEASE}
        DISTRIB_RELEASE=${RHRELEASE}
        DISTRIB_ID=${RHRELEASE}
        DISTRIB_CODENAME=$(echo $DISTRIB_CODENAME |sed -e "s/.*(\([^)]\+\))/\1/")
        DISTRIB_RELEASE=$(echo $DISTRIB_RELEASE |sed -e "s/release \([0-9]\)/\1/")
        DISTRIB_ID=$(echo $DISTRIB_ID | awk '{print tolower($1)}')
    else
        if ! ( echo ${@-} | grep -q no_fail );then
            echo "unexpected case, no lsb_release" >&2
            exit 1
        fi
    fi
    export DISTRIB_ID DISTRIB_CODENAME DISTRIB_RELEASE
}
get_command() {
    local p=
    local cmd="${@}"
    if which which >/dev/null 2>/dev/null;then
        p=$(which "${cmd}" 2>/dev/null)
    fi
    if [ "x${p}" = "x" ];then
        p=$(export IFS=":";
            for pathe in $PATH;do
                pc="${pathe}/${cmd}";
                if [ -x "${pc}" ]; then
                    p="${pc}"
                fi
                if [ "x${p}" != "x" ]; then echo "${p}";break;fi
            done
         )
    fi
    if [ "x${p}" != "x" ];then
        echo "${p}"
    fi
}
cleanup_docker_tag() { echo "${@}"|sed -re "s/\.|[-_]//g"|awk '{print tolower($0)}'; }
get_container_id() { local n=${1};local cid=$(docker ps -q -a --filter 'name='$n); echo "${cid}"; }
sane_container_name() { local n=${1};n=${n//:/};n=${n//_/};n=${n//-/};n=${n//\//};n=${n//\./};echo $n; }
get_images() { docker images --no-trunc -q "${@}" 2>/dev/null|awk '!seen[$0]++'; }
get_image() { get_images "${@}" | head -n 1; }
get_docker_ids() { docker inspect -f '{{.Id}}' "${@}" 2>/dev/null; }
save_container() {
    local n="${1}"
    local d="${2:-${n}}"
    local running=$(docker ps -q    --filter 'name='$n)
    if [ x"${running}" != "x" ];then
        vv docker kill "${running}"
    fi
    local cid=$(get_container_id $n)
    if [ x"${cid}" != "x" ];then
        vv docker commit "$cid" "$d"
        vv docker rm "$cid"
    else
        img=${initial_img}
    fi
}
get_git_changeset() { ( cd "${1:-$(pwd)}" && git log HEAD|head -n1|awk '{print $2}'); }
get_git_branch() {
   ( cd "${1:-$(pwd)}" &&\
     git rev-parse --abbrev-ref HEAD | grep -v HEAD || \
     git describe --exact-match HEAD 2> /dev/null || \
     git rev-parse HEAD)
}
get_git_branchs() { ( cd "${1:-$(pwd)}" && git branch|sed -e "s/^\*\? \+//g"); }
get_full_chrono() { date "+%F_%H-%M-%S-%N"; }
get_random_slug() { len=${1:-32};strings=${2:-'a-zA-Z0-9'};echo "$(cat /dev/urandom|tr -dc "$strings"|fold -w ${len}|head -n 1)"; }
may_sudo() {
    if [ "$(whoami)" != "root" ] && [ -z "${NO_SUDO-}" ];then
        echo "sudo $([ "x$DIRECT_SUDO" = "x" ] && echo "-HE")"
    fi
}
get_ancestor_from_dockerfile() {
    local dockerfile=${1}
    local ancestor=
    if [ -e "${dockerfile}" ] && egrep -q ^FROM "${dockerfile}"; then
        ancestor=$(egrep ^FROM "${dockerfile}"\
            | head -n1 | awk '{print $2}' | xargs -n1| sort -u )
    fi
    echo ${ancestor}
}
do_tmp_cleanup() {
    local tmp_dockers=$2
    local tmp_files=$1
    local tmp_imgs=$3
    log "Post cleanup"
    for tmp_file in ${tmp_files};do
        if [ -e "${tmp_file}" ]; then
            vv rm -f "${tmp_file}"
        fi
    done
    for test_docker in ${tmp_dockers};do
        test_dockerid=$(vvv get_container_id ${test_docker})
        if [ "x${test_dockerid}" != "x" ]; then
            log "Removing produced test docker ${test_docker}"
            docker rm -f "${test_dockerid}"
        fi
    done
    for test_tag in ${tmp_imgs};do
        test_tagid=$(vvv get_image ${test_tag})
        if [ "x${test_tagid}" != "x" ]; then
            log "Removing produced test image: ${test_tag}"
            docker rmi "${test_tagid}"
        fi
    done
}
may_autoadd_git_author() {
    if [ "x$(git config user.email)" = "x" ];then
        echo "-c user.name=Corpusops -c user.email=autocommiter@corpousops"
    fi
}
update_wd_to_br() {
    (
        local wd="${2:-$(pwd)}"
        local up_branch="${1}"
        cd "${wd}" || die "${wd} does not exists"
        if ! git diff --quiet;then
            vvv git $(may_autoadd_git_author) stash
            die_in_error "${wd}: changes can't be stashed"
        fi &&\
            vv git $(may_autoadd_git_author) pull origin "${up_branch}"
    )
}
upgrade_wd_to_br() {
    (
        local wd="${2:-$(pwd)}"
        local up_branch="${1}"
        cd "${wd}" || die "${wd} does not exists"
        local test_branch="${3:-$(get_git_branch)}"
        local existing_gitmodules="$(git submodule status|awk '{print $2}')"
        if [ "x${test_branch}" != "x${up_branch}" ];then
            warn "Upgrading $wd to branch: $up_branch"
            git fetch --all || die "git fetch in $wd failed"
            if get_git_branchs | egrep -q "^${up_branch}$";then
                vv git checkout ${up_branch} &&\
                    vv git reset --hard origin/${up_branch}
            else
                vv git checkout origin/${up_branch} -b ${up_branch}
            fi
        fi
        update_wd_to_br "$up_branch" "$wd" &&\
        echo "${existing_gitmodules}" | while read subdir;do
            subdir=$(echo $subdir|sed -e "s/^\.\///g")
            if [ -h "${subdir}/.git" ] || [ -f "${subdir}/.git" ];then
                debug "Checking if ${subdir} is always a submodule"
                if [ -e .gitmodules ] && ( grep -q -- "${subdir}" .gitmodules );then
                    debug "${subdir} is always a gitmodule"
                else
                    warn "${subdir} is not a git submodule anymore"
                    vv rm -rf "${subdir}"
                fi
            fi
        done
        if [ -e .gitmodules ];then
            warn "Upgrading submodules in $wd"
            vv git submodule update --recursive
        fi
    )
}
get_python2() {
    local py2=
    for i in python2.7 python2.6 python-2.7 python-2.6 python-2;do
        local lpy=$(get_command $i 2>/dev/null)
        if [ "x$lpy" != "x" ] && ( ${lpy} -V 2>&1| egrep -qi 'python 2' );then
            py2=${lpy}
            break
        fi
    done
    echo $py2
}
get_python3() {
    local py3=
    for i in python3.9 python3.8 python3.7 python3.6 \
             python-3.9 python-3.8 python-3.7 python3.6 \
             python-3;do
        local lpy=$(get_command $i 2>/dev/null)
        if [ "x$lpy" != "x" ] && ( ${lpy} -V 2>&1| egrep -qi 'python 3' );then
            py3=${lpy}
            break
        fi
    done
    echo $py3
}
has_python_module() {
    local py="${py:-python}"
    for i in $@;do
        if ! ( "${py}" -c "import $i" 2>/dev/null );then
            return 1
        fi
     done
}
pymod_ver() {
    local mod="${1}"
    local py="${2:-${py:-python}}"
    "$py" -c "from __future__ import print_function;import $mod;print($mod.__version__)"
}
install_pip() {
    local py="${1:-python}"
    local DEFAULT_PIP_URL="https://bootstrap.pypa.io/get-pip.py"
    local PIP_URL="${PIP_URL:-$DEFAULT_PIP_URL}"
    PIP_INST="$(mktemp)"
    log "Reinstalling pip via $PIP_URL (copy to $PIP_INST)"
    if ! ( "$py" -c "import urllib; print urllib.urlopen('$PIP_URL').read()" > "$PIP_INST" );then
        log "Error downloading pip installer"
        return 1
    fi
    $(may_sudo) "$py" "$PIP_INST" -U pip setuptools six
}
uninstall_at_least_pymodule() {
    local py="${3:-${py-python}}"
    local ver="${2}"
    local mod="${1}"
    local import="${4:-${1}}"
    if ( ( has_python_module "$mod" ) && ( version_lt "$(pymod_ver "$mod" "$py")" "$ver" ) );then
        local modd=$($py -c "from __future__ import print_function;import $import,os;print(os.path.dirname($import.__file__.replace('/__init__.pyc', '')))")
        submods=$(echo "$import"|grep -o "\."|wc -l)
        if [ $submods -gt 0 ];then
            for i in $(seq 1 $submods);do
                modd=$modd/..
            done
            modd=$(cd "$modd" && pwd)
        fi
        local modb="$HOME/.$mod.backup.$chrono.tar.bz2"
        local importp=${import//.//}
        ( log "Backup mod install in $modb" \
          && if [ -e "$modd/${importp}.py" ];then
            tar cjf "$modb" $modd/${importp}.py* $modd/${mod}*egg-info &&\
                $(may_sudo) rm -rf $modd/${importp}.py* $modd/${mod}*egg-info; \
            elif [ -e "$modd/${importp}" ];then
                tar cjf "$modb" $modd/${importp} $modd/${mod}*egg-info &&\
                    $(may_sudo) rm -rf $modd/${importp} $modd/${mod}*egg-info; \
            fi && log "Upgrading now from legacy pre $mod $ver" ) || \
        die_in_error "Removing legacy $mod failed"
    fi
}
upgrade_pip() {
    local py="${1:-python}"
    local pyc="$(get_command "$py")"
    local dpy="$(dirname $pyc)"
    local chrono=$(date +%F_%T|sed -e "s/:/-/g")
    # force reinstalling pip in same place where it is (not /usr/local but /usr)
    # __version__ is set by pip, uninstall last
    if ( version_lt "$($py -V 2>&1|awk '{print $2}')" "3.0" );then
        vv uninstall_at_least_pymodule requests  2.18.3 "$py"
        vv uninstall_at_least_pymodule pyasn1    0.4.2  "$py"
        vv uninstall_at_least_pymodule urllib3   1.20   "$py"
        vv uninstall_at_least_pymodule pyopenssl 18.0.0 "$py" OpenSSL
        vv uninstall_at_least_pymodule backports.ssl_match_hostname 3.7.0 "$py" backports.ssl_match_hostname
    fi
    uninstall_at_least_pymodule six     1.11.0
    uninstall_at_least_pymodule chardet 2.3.0
    uninstall_at_least_pymodule pip     2.0
    if ! ( has_python_module pip );then
        install_pip "$py" || die "pip install failed for $py"
        if ! ( has_python_module pip );then
            log "pip not found for $py"
            return 1
        fi
    fi
    log "ReInstalling pip for $py"
    if ( corpusops_use_venv );then
        local maysudo=""
    else
        local maysudo=$(may_sudo)
    fi
    vv $maysudo "${py}" -m pip install -U setuptools \
        && vv $maysudo "${py}" -m pip install -U pip six urllib3\
        && vv $maysudo "${py}" -m pip install chardet \
        && if ( version_lt "$($py -V 2>&1|awk '{print $2}')" "3.0" );then
            vv $maysudo "${py}" -m pip install -U backports.ssl_match_hostname ndg-httpsclient pyasn1 &&\
            vv $maysudo "${py}" -m pip install urllib3 pyopenssl
        fi
}
make_virtualenv() {
    local py=${1:-$(get_python2)}
    local DEFAULT_VENV_PATH=$SCRIPT_ROOT/venv
    local venv_path=${2-${VENV_PATH:-$DEFAULT_VENV_PATH}}
    local venv=$(get_command $(basename ${VIRTUALENV_BIN:-virtualenv}))
    local PIP_CACHE=${PIP_CACHE:-${venv_path}/cache}
    if [ ! -e "${venv_path}" ];then
        mkdir -p "${venv_path}"
    fi
    if     [ ! -e "${venv_path}/bin/activate" ] \
        || [ ! -e "${venv_path}/lib" ] \
        || [ ! -e "${venv_path}/include" ] \
        ; then
        bs_log "Creating virtualenv in ${venv_path}"
        if [ ! -e "${PIP_CACHE}" ]; then
            mkdir -p "${PIP_CACHE}"
        fi
    $venv \
        $( [ "x$py" != "x" ] && echo "--python=$py"; ) \
        --system-site-packages --unzip-setuptools \
        "${venv_path}" &&\
    ( . "${venv_path}/bin/activate" &&\
      upgrade_pip "${venv_path}/bin/python" &&\
      deactivate; )
    fi
    if [ "x${DEFAULT_VENV_PATH}" != "${venv_path}" ];then
        if [ -h $DEFAULT_VENV_PATH ] &&\
            [ "x$(readlink $DEFAULT_VENV_PATH)" != "$venv_path" ];then
            rm -f "${DEFAULT_VENV_PATH}"
        fi
        if [ -e "${DEFAULT_VENV_PATH}" ] && \
            [ "$DEFAULT_VENV_PATH" != "$venv_path" ] &&\
            [ ! -h "${DEFAULT_VENV_PATH}" ];then
            die "$DEFAULT_VENV_PATH is not a symlink but we want to create it"
        fi
        if [ ! -e $DEFAULT_VENV_PATH ];then
            ln -s "${venv_path}" "${DEFAULT_VENV_PATH}"
        fi
    fi
}
ensure_last_python_requirement() {
    local COPS_PYTHON=${COPS_PYTHON:-python}
    local COPS_UPGRADE=${COPS_UPGRADRE:-"-U"}
    local PIP_CACHE=${PIP_CACHE:-${VENV_PATH:-$(pwd)}/cache}
    # inside the for loop as at first pip can not have the opts
    # but can be upgraded to have them after
    local copt=
    if "$py" -m pip --help | grep -q download-cache; then
        copt="--download-cache"
    elif "$py" -m pip --help | grep -q cache-dir; then
        copt="--cache-dir"
    fi
    log "Installing last version of $@"
    if ( corpusops_use_venv );then
        local maysudo=""
    else
        local maysudo=$(may_sudo)
    fi
    if [ "x$copt" != "x" ];then
        vvv $maysudo "$COPS_PYTHON" -m pip install \
            --src "$(get_eggs_src_dir)" $COPS_UPGRADE $copt "${PIP_CACHE}" $@
    else
        vvv $maysudo "$COPS_PYTHON" -m pip install \
            --src "$(get_eggs_src_dir)" $COPS_UPGRADE $@
    fi
}
usage() { die 128 "No usage found"; }
# END: corpusops common glue

W=$OW
DEFAULT_COPS_ROOT="/srv/corpusops/corpusops.bootstrap"
DEFAULT_COPS_URL="https://github.com/corpusops/corpusops.bootstrap.git"
COPS_URL=${COPS_URL-$DEFAULT_COPS_URL}
COPS_ROOT=${COPS_ROOT:-$W/local/corpusops.bootstrap}
HOST_MOUNTPOINT=${COPS_HOST_MOUNTPOINT:-/host}
HOST_COPS=${COPS_HOST_COPS:-$HOST_COPS/local/corpusops.bootstrap}
VMS_MOUNT_PATH=${VMS_MOUNT_PATH:-$W/local/mountpoint}
# vim:set et sts=4 ts=4 tw=80:
