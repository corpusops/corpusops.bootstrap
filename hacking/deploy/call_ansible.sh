#!/usr/bin/env bash
set -e
if [ -e .ansible/scripts/ansible_deploy_env ];then
    . .ansible/scripts/ansible_deploy_env
fi
PLAYBOOK=${PLAYBOOK-}
if [[ -z $PLAYBOOK ]] && [[ -z $@ ]];then
    log "Either set \$PLAYBOOK var or give arguments to $0"
    exit 0
fi
set_vaultpwfiles
log "-> In $COPS_CWD"
launchlog="$AP $vaultpwfiles $A_INVENTORY \
      ${A_CUSTOM_ARGS-} \
      ${PLAYBOOK_PRE_ARGS-} ${PLAYBOOK_PRE_CUSTOM_ARGS-} \
      $PLAYBOOK \
      ${PLAYBOOK_POST_ARGS-} ${PLAYBOOK_POST_CUSTOM_ARGS-} \
      ${@-}"
if [[ -n ${ANSIBLE_DRY_RUN-${DRY_RUN-}} ]];then
    log "Would have run $launchlog"
    exit 0
else
    if [[ -z $NONINTERACTIVE ]];then
        log "Do you really want to launch: $launchlog"
        log "[Y/N] ?"
        while read i;do
            if echo $i | egrep -iq "^(y|yes|oui|o)";then
                break
            else
                log "aborting"
                exit 16
            fi
        done
    fi
fi
debug "vaultpwfiles: $vaultpwfiles"
debug "launching: $launchlog"
# Do not set inventory if redefined in $@
_A_INVENTORY=$A_INVENTORY
if echo $@ | egrep -iq -- "(( -i )|(--(inventory-file|inventory)(=| )))";then
    debug "Inventory CLI switch detected, removing default one"
    _A_INVENTORY=
# Let a way to fallback on ansible binary
_AP=$AP
if [[ -n "$CALL_ANSIBLE_USE_ANSIBLE" ]];then
    _AP=$ANSIBLE_BIN
fi
if [[ -z "${NO_SILENT-}" ]];then
    if [[ -n "${@}" ]];then
        $LOCAL_COPS_ROOT/bin/silent_run \
            $_AP $vaultpwfiles $_A_INVENTORY \
            ${A_CUSTOM_ARGS-} \
            ${PLAYBOOK_PRE_ARGS-} ${PLAYBOOK_PRE_CUSTOM_ARGS-} \
            $PLAYBOOK \
            ${PLAYBOOK_POST_ARGS-} \
            ${PLAYBOOK_POST_CUSTOM_ARGS-} \
            "${@}"
    else
        $LOCAL_COPS_ROOT/bin/silent_run \
            $_AP $vaultpwfiles $_A_INVENTORY \
            ${A_CUSTOM_ARGS-} \
            ${PLAYBOOK_PRE_ARGS-} ${PLAYBOOK_PRE_CUSTOM_ARGS-} \
            $PLAYBOOK \
            ${PLAYBOOK_POST_ARGS-} \
            ${PLAYBOOK_POST_CUSTOM_ARGS-}
    fi
else
    if [[ -n "${@}" ]];then
        $_AP $vaultpwfiles $_A_INVENTORY \
            ${A_CUSTOM_ARGS-} \
            ${PLAYBOOK_PRE_ARGS-} ${PLAYBOOK_PRE_CUSTOM_ARGS-} \
            $PLAYBOOK \
            ${PLAYBOOK_POST_ARGS-} ${PLAYBOOK_POST_CUSTOM_ARGS-} \
            "${@}"
    else
        $_AP $vaultpwfiles $_A_INVENTORY \
            ${A_CUSTOM_ARGS-} \
            ${PLAYBOOK_PRE_ARGS-} ${PLAYBOOK_PRE_CUSTOM_ARGS-} \
            $PLAYBOOK \
            ${PLAYBOOK_POST_ARGS-} ${PLAYBOOK_POST_CUSTOM_ARGS-} \
            "${@}"
    fi
fi
