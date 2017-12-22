#!/usr/bin/env bash
set -e

COPS_SCRIPTS_DIR="${COPS_SCRIPTS_DIR-$(cd "$(dirname "$0")" && pwd)}"
export ADEBUG=1
if [ -e "$COPS_SCRIPTS_DIR/ansible_deploy_env" ];then
    . "$COPS_SCRIPTS_DIR/ansible_deploy_env"
    print_env
fi
if [ ! -e "$COPS_SCRIPTS_DIR/ansible_deploy_env" ];then
    exit 1
fi
