#!/usr/bin/env bash
set -e

COPS_SCRIPTS_DIR="${COPS_SCRIPTS_DIR:-$(cd "$(dirname "$0")" && pwd)}"
SAVED_SECRET_VAULTS=${SECRET_VAULTS-}
if [ -e "$COPS_SCRIPTS_DIR/ansible_deploy_env" ];then
    . "$COPS_SCRIPTS_DIR/ansible_deploy_env"
fi

usage() {
    NO_HEADER=y die '
[A_ENV_NAME= ] \\
[A_CRYPTED_VAULTS= ] \\
    '$0' [vaultfile1] [vaultfile2] ...

Wrapper to call ansible-vault with the selected vault password file,
according to $A_ENV_NAME or DEFAULT_PASWORD

'
}

parse_cli $@

A_CRYPTED_VAULTS=${@:-${A_CRYPTED_VAULTS}}

edit_vault() {
    local vault=$1
    if [ -e $vault ];then mode=edit;else mode=create;fi
    debug "${mode}: $vault"
    warn_vault
    vaultd="$(dirname "$vault")"
    bvaultd=$(basename $vaultd)
    bvault=$(basename $vault .yml)
    if [ ! -e "$vaultd" ];then mkdir -p "$vaultd";fi
    if [[ -z $SAVED_SECRET_VAULTS ]];then
        unset SECRET_VAULTS
    else
        export SECRET_VAULTS="$SAVED_SECRET_VAULTS"
    fi
    if [ -e "$INVENTORY_GROUPVARS" ];then
        debug "Using vaults inside groups"
        export A_ENV_NAME=$bvaultd
    else
        debug "Using vaults inside vaults folders"
        export A_ENV_NAME=$bvault
    fi
    reset_vaults
    set_vaultpwfiles
    vv ansible-vault $mode $vaultpwfiles $vault
}

# edit in subshell as we may play with different A_ENV_NAME
for VAULT in $A_CRYPTED_VAULTS;do if ! ( edit_vault $VAULT );then exit 1;fi;done
