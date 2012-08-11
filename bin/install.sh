#!/usr/bin/env bash
# SEE CORPUSOPS DOCS FOR FURTHER INSTRUCTIONS
THIS="$(readlink -f "${0}")"
LAUNCH_ARGS=${@}
ERROR_MSG="There were errors"
RED="\\e[0;31m"
CYAN="\\e[0;36m"
YELLOW="\\e[0;33m"
NORMAL="\\e[0;0m"

bs_log(){
    printf "${RED}[bs] ${@}${NORMAL}\n";
}

bs_yellow_log(){
    printf "${YELLOW}[bs] ${@}${NORMAL}\n";
}

die_() {
    ret=${1}
    shift
    printf "${CYAN}PROBLEM DETECTED, BOOTCORPUS FAILED${NORMAL}\n" 1>&2
    echo "${@}" 1>&2
    exit $ret
}

die() {
    die_ 1 ${@}
}

die_in_error_() {
    ret=${1}
    shift
    msg="${@:-"$ERROR_MSG"}"
    if [ "x${ret}" != "x0" ]; then
        die_ "${ret}" "${msg}"
    fi
}

die_in_error() {
    die_in_error_ "${?}" "${@}"
}

test_online() {
    ping -W 10 -c 1 8.8.8.8 1>/dev/null 2>/dev/null
    if [ "x${?}" = "x0" ] || [ "x${TRAVIS}" != "x" ]; then
        return 0
    fi
    return 1
}

detect_os() {
    UNAME="${UNAME:-"$(uname | awk '{print tolower($1)}')"}"
    PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
    SED=$(which sed)
    if [ "x${UNAME}" != "xlinux" ]; then
        SED=$(which gsed)
    fi
    DISTRIB_CODENAME=""
    DISTRIB_ID=""
    if hash -r lsb_release >/dev/null 2>&1; then
        DISTRIB_ID=$(lsb_release -si)
        DISTRIB_CODENAME=$(lsb_release -sc)
        DISTRIB_RELEASE=$(lsb_release -sr)
    else
        echo "unespected case, no lsb_release"
        exit 1
    fi
}

get_chrono() {
    date "+%F_%H-%M-%S"
}

get_full_chrono() {
    date "+%F_%H-%M-%S-%N"
}

set_colors() {
    if [ "x${NO_COLORS}" != "x" ]; then
        YELLOW=""
        RED=""
        CYAN=""
        NORMAL=""
    fi
}

get_conf() {
    key="${1}"
    echo $(cat "${CORPUS_OPS_PREFIX}/.corpusops/$key" 2>/dev/null)
}

store_conf() {
    key="${1}"
    val="${2}"
    if [ ! -e "${CORPUS_OPS_PREFIX}/.corpusops" ]; then
        mkdir -p "${CORPUS_OPS_PREFIX}/.corpusops"
        chmod 700 "${CORPUS_OPS_PREFIX}/.corpusops"
    fi
    if [ -e "${CORPUS_OPS_PREFIX}/.corpusops" ]; then
        echo "${val}">"${CORPUS_OPS_PREFIX}/.corpusops/${key}"
    fi
}

remove_conf() {
    for key in $@;do
        if [ -e "${CORPUS_OPS_PREFIX}/.corpusops/${key}" ]; then
            rm -f "${CORPUS_OPS_PREFIX}/.corpusops/${key}"
        fi
    done
}

get_default_knob() {
    key="${1}"
    stored_param="$(get_conf ${key})"
    cli_param="${2}"
    default="${3:-}"
    if [ "x${cli_param}" != "x" ]; then
        setting="${cli_param}"
    elif [ "x${stored_param}" != "x" ]; then
        setting="${stored_param}"
    else
        setting="${default}"
    fi
    if [ "x${stored_param}" != "x${setting}" ] && [ "x${setting}" != "x${default}" ]; then
        store_conf ${key} "${setting}"
    else
        remove_conf "${key}"
    fi
    echo "${setting}"
}

get_corpusops_orga_url() {
    get_default_knob corpusops_orga_url "${CORPUSOPS_ORGA_URL}" \
        "https://github.com/corpusops"
}

get_corpusops_url() {
    get_default_knob corpusops_url "${CORPUSOPS_URL}" \
        "$(get_corpusops_orga_url)/corpusops.bootstrap.git"
}

get_ansible_url() {
    get_default_knob ansible_url "${ANSIBLE_URL}"  \
        "https://github.com/corpusops/ansible.git"
}

get_corpusops_branch() {
    get_default_knob corpusops_branch "${CORPUSOPS_BRANCH}" "master"
}

get_ansible_branch() {
    get_default_knob ansible_branch "${ANSIBLE_BRANCH}" "stable-2.2"
}

set_vars() {
    set_colors
    SCRIPT_DIR="$(dirname $THIS)"
    QUIET=${QUIET:-}
    CORPUS_OPS_PREFIX="$(dirname ${SCRIPT_DIR})"
    CHRONO="$(get_chrono)"
    TRAVIS_DEBUG="${TRAVIS_DEBUG:-}"
    DO_NOCONFIRM="${DO_NOCONFIRM-}"
    DO_VERSION="${DO_VERSION-"no"}"
    DO_ONLY_SYNC_CODE="${DO_ONLY_SYNC_CODE-""}"
    DO_SYNC_CODE="${DO_SYNC_CODE-"y"}"
    DO_INSTALL_PREREQUISITES="${DO_INSTALL_PREREQUISITES-"y"}"
    DO_SETUP_VIRTUALENV="${DO_SETUP_VIRTUALENV-"y"}"
    if [ "x${DO_VERSION}" != "xy" ];then
        DO_VERSION="no"
    fi
    TMPDIR="${TMPDIR:-"/tmp"}"
    BASE_PACKAGES="python-software-properties curl python-virtualenv git rsync bzip2"
    BASE_PACKAGES="${BASE_PACKAGES} acl build-essential m4 libtool pkg-config autoconf gettext"
    BASE_PACKAGES="${BASE_PACKAGES} groff man-db automake tcl8.5 debconf-utils swig"
    BASE_PACKAGES="${BASE_PACKAGES} libsigc++-2.0-dev libssl-dev libgmp3-dev python-dev python-six"
    BASE_PACKAGES="${BASE_PACKAGES} libffi-dev"
    VENV_PATH="${VENV_PATH:-"${CORPUS_OPS_PREFIX}/venv"}"
    EGGS_GIT_DIRS="ansible"
    PIP_CACHE="${VENV_PATH}/cache"
    if [ "x${QUIET}" = "x" ]; then
        QUIET_GIT=""
    else
        QUIET_GIT="-q"
    fi
    # export variables to survive a restart/fork
    export SED PATH UNAME
    export DISTRIB_CODENAME DISTRIB_ID DISTRIB_RELEASE
    #
    export CORPUSOPS_ORGA_URL="$(get_corpusops_orga_url)"
    export CORPUSOPS_URL="$(get_corpusops_url)"
    export CORPUSOPS_BRANCH="$(get_corpusops_branch)"
    #
    export ANSIBLE_URL="$(get_ansible_url)"
    export ANSIBLE_BRANCH="$(get_ansible_branch)"
    #
    export EGGS_GIT_DIRS
    #
    export BASE_PACKAGES
    #
    export DO_NOCONFIRM
    export DO_VERSION
    export DO_ONLY_SYNC_CODE
    export DO_SYNC_CODE
    export DO_INSTALL_PREREQUISITES
    export DO_SETUP_VIRTUALENV
    #
    export TRAVIS_DEBUG TRAVIS
    #
    export QUIET
    #
    export VENV_PATH PIP_CACHE CORPUS_OPS_PREFIX
}

check_py_modules() {
    # test if salt binaries are there & working
    bin="${VENV_PATH}/bin/python"
    "${bin}" << EOF
import ansible
import dns
import docker
import chardet
import OpenSSL
import urllib3
import ipaddr
import ipwhois
import pyasn1
from corpusops import version
from distutils.version import LooseVersion
OpenSSL_version = LooseVersion(OpenSSL.__dict__.get('__version__', '0.0'))
if OpenSSL_version <= LooseVersion('0.15'):
    raise ValueError('trigger upgrade pyopenssl')
# futures
import concurrent
EOF
    return ${?}
}

recap_(){
    need_confirm="${1}"
    bs_yellow_log "----------------------------------------------------------"
    bs_yellow_log " CORPUSOPS BOOTSTRAPPER (@$(get_ansible_branch)) FOR $DISTRIB_ID"
    bs_yellow_log "   - ${THIS} [--help] [--long-help]"
    bs_yellow_log "----------------------------------------------------------"
    bs_log "DATE: ${CHRONO}"
    bs_log "CORPUS_OPS_PREFIX: ${CORPUS_OPS_PREFIX}"
    bs_yellow_log "---------------------------------------------------"
    if [ "x${need_confirm}" != "xno" ] && [ "x${DO_NOCONFIRM}" = "x" ]; then
        bs_yellow_log "To not have this confirmation message, do:"
        bs_yellow_log "    export DO_NOCONFIRM='1'"
    fi
}

recap() {
    will_do_recap="x"
    if [ "x${QUIET}" != "x" ]; then
        will_do_recap=""
    fi
    if [ "x${will_do_recap}" != "x" ]; then
        recap_
        travis_sys_info
    fi
}

is_apt_installed() {
    if ! dpkg-query -s ${@} 2>/dev/null|egrep "^Status:"|grep -q installed; then
        return 1
    fi
}

is_pkg_installed() {
    if lsb_release  -si 2>/dev/null | egrep -iq "debian|ubuntu";then
        is_apt_installed "${@}"
        return $?
    else
        return 1
    fi
}

may_sudo() {
    if [ "$(whoami)" != "root" ];then
        echo "sudo"
    fi
}

deb_install() {
    to_install=${@}
    bs_log "Installing ${to_install}"
    cmd=""
    CORPUSOPS_WITH_PKGMGR_UPDATE=""
    if [ "x${CORPUSOPS_WITH_PKGMGR_UPDATE}" != "x" ]; then
        cmd="apt-get update &&"
    fi
    $(may_sudo) sh -c "$cmd apt-get install -y --force-yes ${to_install}"
}

install_packages() {
    if lsb_release  -si 2>/dev/null | egrep -iq "debian|ubuntu";then
        deb_install "${@}"
    else
        return 0
    fi
}

lazy_pkg_install() {
    CORPUSOPS_WITH_PKGMGR_UPDATE=${CORPUSOPS_WITH_PKGMGR_UPDATE:-}
    to_install=""
    for i in ${@};do
         if ! is_pkg_installed ${i}; then
             to_install="${to_install} ${i}"
         fi
    done
    if [ "x${to_install}" != "x" ]; then
        install_packages ${to_install}
    fi
}

install_prerequisites() {
    if [ "x${DO_INSTALL_PREREQUISITES}" != "xy" ]; then
        bs_log "prerequisites setup skipped"
        return 0
    fi
    if [ "x${QUIET}" = "x" ]; then
        bs_log "Check package dependencies"
    fi
    CORPUSOPS_WITH_PKGMGR_UPDATE="y" lazy_pkg_install ${BASE_PACKAGES} \
        || die " [bs] Failed install rerequisites"
}

sys_info(){
    set -x
    ps aux
    netstat -pnlt
    set +x
}

travis_sys_info() {
    if [ "x${TRAVIS}" != "xtravis" ] && [ "x${TRAVIS_DEBUG}" != "x" ]; then
        sys_info
    fi
}

get_git_branch() {
    cd "${1}" 1>/dev/null 2>/dev/null
    br="$(git branch | grep "*"|grep -v grep)"
    echo "${br}" | "${SED}" -e "s/\* //g"
    cd - 1>/dev/null 2>/dev/null
}

checkout_code() {
    if "${VENV_PATH}/bin/ansible-playbook" --help 2>&1 >/dev/null;then
        cd "${CORPUS_OPS_PREFIX}" &&\
            bin/ansible-playbook -i localhost, -vvvv -c local\
                requirements/checkouts.yml  \
                -e "prefix='$PWD' venv='${VENV_PATH}'" &&\
                if [ "x${QUIET}" = "x" ]; then
                    bs_log "Code updated"
                fi
    else
        bs_yellow_log "Cant sync code, bootstrap core is not done"
        return 1
    fi
}

synchronize_code() {
    if [ "x${DO_SYNC_CODE}" = "xno" ]; then
        if [ "x${QUIET}" = "x" ];then
            bs_log "Sync code skipped"
        fi
        return 0
    fi
    if [ "x${CORPUS_OPS_IN_RESTART}" = "x" ] && test_online; then
        if [ "x${QUIET}" = "x" ];then
            bs_yellow_log "If you want to skip checkouts, next time, do export DO_SYNC_CODE=no"
        fi
        checkout_code
    fi
    return $ret
}

setup_virtualenv() {
    if [ "x${DO_SETUP_VIRTUALENV}" != "xy" ]; then
        bs_log "virtualenv setup skipped"
        return 0
    fi
    if     [ ! -e "${VENV_PATH}/bin/activate" ] \
        || [ ! -e "${VENV_PATH}/lib" ] \
        || [ ! -e "${VENV_PATH}/include" ] \
        ; then
        bs_log "Creating virtualenv in ${VENV_PATH}"
        if [ ! -e "${PIP_CACHE}" ]; then
            mkdir -p "${PIP_CACHE}"
        fi
        if [ ! -e "${VENV_PATH}" ]; then
            mkdir -p "${VENV_PATH}"
        fi
        virtualenv --system-site-packages --unzip-setuptools "${VENV_PATH}" &&\
        . "${VENV_PATH}/bin/activate" &&\
        "${VENV_PATH}/bin/easy_install" -U setuptools &&\
        "${VENV_PATH}/bin/pip" install -U pip &&\
        deactivate
    fi
    # virtualenv is present, activate it
    if [ -e "${VENV_PATH}/bin/activate" ]; then
        if [ "x${QUIET}" = "x" ]; then
            bs_log "Activating virtualenv in ${VENV_PATH}"
        fi
        . "${VENV_PATH}/bin/activate"
    fi
    # install requirements
    cd "${CORPUS_OPS_PREFIX}"
    install_git=""
    for i in ${EGGS_GIT_DIRS};do
        if [ ! -e "${VENV_PATH}/src/${i}" ]; then
            install_git="x"
        fi
    done
    uflag=""
    if check_py_modules; then
        if [ "x${QUIET}" = "x" ]; then
            bs_log "Pip install in place"
        fi
    else
        bs_log "Python install incomplete"
        if pip --help | grep -q download-cache; then
            copt="--download-cache"
        else
            copt="--cache-dir"
        fi
        pip install -U $copt "${PIP_CACHE}" -r requirements/requirements.txt
        die_in_error "requirements/requirements.txt doesn't install"
        if [ "x${install_git}" != "x" ]; then
            # ansible, salt & docker had bad history for
            # their deps in setup.py we ignore them and manage that ourselves
            pip install -U $copt "${PIP_CACHE}" --no-deps \
                -r requirements/git_requirements.txt
            die_in_error "requirements/git_requirements.txt doesn't install"
        else
            cwd="${PWD}"
            for i in ${EGGS_GIT_DIRS};do
                if [ -e "${VENV_PATH}/src/${i}" ]; then
                    cd "${VENV_PATH}/src/${i}"
                    pip install --no-deps -e .
                fi
                cd "${cwd}"
            done
        fi
        pip install --no-deps -e .
        die_in_error "corpusops doesn't install"
    fi
}

reconfigure() {
    for i in \
        ${CORPUS_OPS_PREFIX}/requirements/git_requirements.txt \
        ${CORPUS_OPS_PREFIX}/requirements/checkouts.yml \
    ;do
        ${SED} -r \
            -e "s#^\# (-e.*__(ANSIBLE))#\1#g" \
            -e "s#__CORPUSOPS_ORGA_URL__#$(get_corpusops_orga_url)#g" \
            -e "s#__CORPUSOPS_URL__#$(get_corpusops_url)#g" \
            -e "s#__CORPUSOPS_BRANCH__#$(get_corpusops_branch)#g" \
            -e "s#__ANSIBLE_URL__#$(get_ansible_url)#g" \
            -e "s#__ANSIBLE_BRANCH__#$(get_ansible_branch)#g" \
            "${i}.in" > "${i}"
    done
}

link_dir() {
    where="${2}"
    vpath="${3:-${VENV_PATH}}"
    for i in $1;do
        origin="${vpath}/${i}"
        linkname=$(echo ${i} | ${SED} -re "s|${vpath}/?||g")
        destination="${where}/${linkname}"
        if [ ! -e ${origin} ];then
            mkdir -pv "${origin}"
        fi
        if [ -d "${destination}" ] && [ ! -h "${destination}" ]; then
            if [ ! -e "${where}/nobackup" ]; then
                mkdir "${where}/nobackup"
            fi
            echo "moving old directory; \"${where}/${linkname}\" to \"${where}/nobackup/${linkname}-$(date "+%F-%T-%N")\""
            mv "${destination}" "${where}/nobackup/${linkname}-$(date "+%F-%T-%N")"
        fi
        do_link="1"
        if [ -h "${destination}" ]; then
            if [ "x$(readlink ${destination})" = "x${origin}" ]; then
                do_link=""
            else
                rm -v "${destination}"
            fi
        fi
        if [ "x${do_link}" != "x" ]; then
            ln -sfv "${origin}" "${destination}" ||
                die "ln ${origin} -> ${destination} failed"
        fi
    done
}

bs_help() {
    title=${1}
    shift
    help=${1}
    shift
    default=${1}
    shift
    opt=${1}
    shift
    msg="     ${YELLOW}${title} ${NORMAL}${CYAN}${help}${NORMAL}"
    if [ "x${opt}" = "x" ]; then
        msg="${msg} ${YELLOW}(mandatory)${NORMAL}"
    fi
    if [ "x${default}" != "x" ]; then
        msg="${msg} ($default)"
    fi
    printf "${msg}\n"
}

print_contrary() {
    if [ "x${1}" = "x" ];then
        echo "y"
    else
        echo "n"
    fi
}

usage() {
    set_colors
    bs_log "${THIS}:"
    echo
    bs_yellow_log "This script will install corpusops & prerequisites"
    echo
    bs_log "  Actions (no action means install)"
    bs_help "    -S|--skip-checkouts" "Skip code synchronnization" \
        "$(print_contrary ${DO_ONLY_SYNC_CODE})" y
    bs_help "    --skip-prereqs" "Skip prereqs install" "${DO_INSTALL_PREREQUISITES}" y
    bs_help "    --skip-venv" "Do not run the virtualenv setup"  "${DO_SETUP_VIRTUALENV}" y
    bs_help "    --only-synchronize-code" "Only sync sourcecode" "${DO_ONLY_SYNC_CODE}" y
    bs_help "    -h|--help / -l/--long-help" "this help message or the long & detailed one" "" y
    bs_help "    --version" "show corpusops version & exit" "${DO_VERSION}" y
    echo
    bs_log "  General settings"
    bs_help "    --corpusops-orga_url <url>" "corpusops orga  fork git url" \
        "$(get_corpusops_orga_url)" y
    bs_help "    --corpusops-url <url>" "corpusops orga fork git url" "$(get_corpusops_url)" y
    bs_help "    --corpusops-branch <branch>" "corpusops fork git branch" "$(get_corpusops_branch)" y
    bs_help "    --ansible-url <url>" "ansible fork git url" "$(get_ansible_url)" y
    bs_help "    --ansible-branch <branch>" "ansible fork git branch" "$(get_ansible_branch)" y
    bs_help "    -C|--no-confirm" "Do not ask for start confirmation" "" y
    bs_help "    --no-colors" "No terminal colors" "${NO_COLORS}" "y"
}

parse_cli_opts() {
    #set_vars # to collect defaults for the help message
    args="${@}"
    PARAM=""
    while true
    do
        sh=1
        argmatch=""
        if [ "x${1}" = "x${PARAM}" ]; then
            break
        fi
        if [ "x${1}" = "x-q" ] || [ "x${1}" = "x--quiet" ]; then
            QUIET="1";argmatch="1"
        fi
        if [ "x${1}" = "x--version" ];then
            DO_VERSION="y";argmatch="1"
        fi
        if [ "x${1}" = "x-h" ] || [ "x${1}" = "x--help" ]; then
            USAGE="1";argmatch="1"
        fi
        if [ "x${1}" = "x-l" ] || [ "x${1}" = "x--long-help" ]; then
            CORPUS_LONG_HELP="1";USAGE="1";argmatch="1"
        fi
        if [ "x${1}" = "x--no-colors" ]; then
            NO_COLORS="1";argmatch="1"
        fi
        if [ "x${1}" = "x-C" ] || [ "x${1}" = "x--no-confirm" ]; then
            DO_NOCONFIRM="y";argmatch="1"
        fi
        # do not remove yet for retro compat
        if [ "x${1}" = "x--skip-prereqs" ]; then
            DO_INSTALL_PREREQUISITES="no"
            argmatch="1"
        fi
        if [ "x${1}" = "x--no-synchronize-code" ]; then
            argmatch="1"
        fi
        if [ "x${1}" = "x-S" ] || [ "x${1}" = "x--skip-checkouts" ]; then
            DO_SYNC_CODE="no";
            argmatch="1"
        fi

        if [ "x${1}" = "x--only-synchronize-code" ]; then
            DO_ONLY_SYNC_CODE="y"
            DO_SYNC_CODE="y"
            argmatch="1"
        fi
        if [ "x${1}" = "x--skip-venv" ]; then
            DO_SETUP_VIRTUALENV="no"
            argmatch="1"
        fi
        if [ "x${1}" = "x--corpusops-orga-url" ]; then
            CORPUSOPS_ORGA_URL="${2}";sh="2";argmatch="1"
        fi
        if [ "x${1}" = "x--corpusops-url" ]; then
            CORPUSOPS_URL="${2}";sh="2";argmatch="1"
        fi
        if [ "x${1}" = "x--corpusops-branch" ]; then
            CORPUSOPS_BRANCH="${2}";sh="2";argmatch="1"
        fi
        if [ "x${1}" = "x--ansible-url" ]; then
            ANSIBLE_URL="${2}";sh="2";argmatch="1"
        fi
        if [ "x${1}" = "x--ansible-branch" ]; then
            ANSIBLE_BRANCH="${2}";sh="2";argmatch="1"
        fi
        if [ "x${argmatch}" != "x1" ]; then
            USAGE="1"
            break
        fi
        PARAM="${1}"
        OLD_ARG="${1}"
        for i in $(seq $sh);do
            shift
            if [ "x${1}" = "x${OLD_ARG}" ]; then
                break
            fi
        done
        if [ "x${1}" = "x" ]; then
            break
        fi
    done
    if [ "x${USAGE}" != "x" ]; then
        set_vars
        usage
        exit 0
    fi
}

setup() {
    detect_os
    parse_cli_opts $LAUNCH_ARGS
    set_vars # real variable affectation
}

main() {
    reconfigure || die "reconfigure failed"
    if [ "x${DO_ONLY_SYNC_CODE}" != "x" ]; then
        synchronize_code || die "synchronize_code failed"
    else
        install_prerequisites || die "install_prerequisites failed"
        setup_virtualenv || die "setup_virtualenv failed"
        synchronize_code || die "synchronize_code failed"
    fi
    if [ "x${QUIET}" = "x" ]; then
        bs_log "end - sucess"
    fi
}

if [ "x${CORPUS_OPS_AS_FUNCS}" = "x" ]; then
    setup
    if [ "x${DO_VERSION}" = "xy" ];then
        echo "$(grep VERSION \
                "${CORPUS_OPS_PREFIX}/src/corpusops/version.py" | cut -d"'" -f2 2>/dev/null)"
        exit 0
    fi
    recap
    main
fi
exit $?
## vim:set et sts=5 ts=4 tw=0:
