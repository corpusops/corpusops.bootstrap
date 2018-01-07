#!/usr/bin/env bash
set -e

COPS_SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -e "$COPS_SCRIPTS_DIR/ansible_deploy_env" ];then
    . "$COPS_SCRIPTS_DIR/ansible_deploy_env"
fi

"$LOCAL_COPS_ROOT/hacking/docker_build_chain.py" $@ 
ret=$?
exit $ret    
