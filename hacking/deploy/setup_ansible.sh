#!/usr/bin/env bash
set -e

COPS_SCRIPTS_DIR="${COPS_SCRIPTS_DIR:-$(cd "$(dirname "$0")" && pwd)}"
if [ -e "$COPS_SCRIPTS_DIR/ansible_deploy_env" ];then
    . "$COPS_SCRIPTS_DIR/ansible_deploy_env"
fi

usage() {
    NO_HEADER=y die '
CORPUSOPS_VAULT_PASSWORD_<env>=verysecret \\
    '$0'

Wrapper to call in this order:
    - "'$COPS_SCRIPTS_DIR'/setup_corpusops.sh"
    - "'$COPS_SCRIPTS_DIR'/setup_core_variables.sh"
    - "'$COPS_SCRIPTS_DIR'/setup_vaults.sh"

'
}

parse_cli $@

vv "$COPS_SCRIPTS_DIR/setup_corpusops.sh"
vv "$COPS_SCRIPTS_DIR/setup_core_variables.sh"
vv "$COPS_SCRIPTS_DIR/setup_vaults.sh"
