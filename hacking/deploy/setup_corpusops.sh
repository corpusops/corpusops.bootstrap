#!/usr/bin/env bash
set -e
export COPS_CWD="${COPS_CWD:-$(pwd)}"
export COPS_ROOT="${COPS_ROOT:-$COPS_CWD/local/corpusops.bootstrap}"
export CORPUSOPS_URL="${CORPUSOPS_URL:-https://github.com/corpusops/corpusops.bootstrap.git}"
if [ -e .ansible/scripts/ansible_deploy_env ];then
    . .ansible/scripts/ansible_deploy_env
fi
sr=$COPS_ROOT/bin/silent_run
installer=$COPS_ROOT/bin/install.sh
if [[ -n ${SKIP_CORPUSOPS_SETUP-} ]];then
    log "-> Skip corpusops setup"
    exit 0
fi
corpusopsinstall() {
    "$sr" "$installer" $@
}
# Run install only
if [[ -z "${SKIP_CORPUSOPS_INSTALL-}" ]] && [ ! -e $COPS_ROOT/venv/bin/ansible ];then
    log "Install a local copy of corpusops"
    if ! corpusopsinstall $CORPUSOPS_INSTALL_ARGS;then
        log "Install error"
        exit 23
    fi
fi
# Update corpusops code, ansible & roles
if [[ -z "${SKIP_CORPUSOPS_UPDATE-}" ]];then
    if ! corpusopsinstall $CORPUSOPS_UPDATE_ARGS;then
        log "Update error"
        exit 24
    fi
else
    log "-> Skip corpusops update"
fi
