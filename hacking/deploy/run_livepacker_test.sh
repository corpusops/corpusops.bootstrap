#!/usr/bin/env bash
#
# Wrappper to launch a container in test mode to debug packer builds
# eg: ./bin/run_livepacker_test.sh .docker/packer/foobar.json
#

COPS_SCRIPTS_DIR="${COPS_SCRIPTS_DIR:-$(cd "$(dirname "$0")" && pwd)}"
if [ -e "$COPS_SCRIPTS_DIR/ansible_deploy_env" ];then
    . "$COPS_SCRIPTS_DIR/ansible_deploy_env"
fi

"$LOCAL_COPS_ROOT/hacking/docker_livepacker_test.sh" $@
# vim:set et sts=4 ts=4 tw=0:
