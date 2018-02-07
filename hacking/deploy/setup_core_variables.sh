#!/usr/bin/env bash
set -e

COPS_SCRIPTS_DIR="${COPS_SCRIPTS_DIR:-$(cd "$(dirname "$0")" && pwd)}"
if [ -e "$COPS_SCRIPTS_DIR/ansible_deploy_env" ];then
    . "$COPS_SCRIPTS_DIR/ansible_deploy_env"
fi


usage() {
    NO_HEADER=y die '

    '$0'

Generate an ansible variable file containing corpusops projects core variables (cops_playbooks, cops_cwd, cops_path)
'
}

parse_cli $@
set_core_variables
