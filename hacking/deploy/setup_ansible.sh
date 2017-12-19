#!/usr/bin/env bash
set -e
ANSIBLE_SCRIPTS_DIR=${ANSIBLE_SCRIPTS_DIR:-$(cd "$(dirname "$(readlink -f "$0")")" && pwd)}
if [ -e $ANSIBLE_SCRIPTS_DIR/ansible_deploy_env ];then
    . $ANSIBLE_SCRIPTS_DIR/ansible_deploy_env
fi
vv "$ANSIBLE_SCRIPTS_DIR/setup_corpusops.sh"
vv "$ANSIBLE_SCRIPTS_DIR/setup_core_variables.sh"
vv "$ANSIBLE_SCRIPTS_DIR/setup_vaults.sh"
