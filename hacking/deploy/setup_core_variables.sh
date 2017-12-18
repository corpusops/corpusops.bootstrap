#!/usr/bin/env bash
set -e
ci_cwd="$(pwd)"
if [ -e .ansible/scripts/ansible_deploy_env ];then
    . .ansible/scripts/ansible_deploy_env
fi
log() { echo "$@" >&2; }
vv() { log "($ci_cwd) $@";"$@"; }
debug() { if [[ -n "${ADEBUG-}" ]];then echo "$@" >&2;fi }
if [ ! -e local ];then
    mkdir local
fi

cat > $COREVARS_VAULT << EOF
---
cops_path: "$COPS_ROOT"
cops_cwd: "$COPS_CWD"
cops_playbooks: "$COPS_PLAYBOOKS"
EOF

log "Core vault: $COREVARS_VAULT"
debug "$(cat $COREVARS_VAULT)"
