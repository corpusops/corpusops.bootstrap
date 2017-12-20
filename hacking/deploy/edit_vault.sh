#!/usr/bin/env bash
set -e
if [ -e .ansible/scripts/ansible_deploy_env ];then
    . .ansible/scripts/ansible_deploy_env
fi
ensure_ansible_env
set_vaultpwfiles
VAULTS=${VAULTS:-${@:-.ansible/vaults/${A_ENV_NAME}.yml}}
edit_vault() {
    local vault=$1
    if [ -e $vault ];then
        mode=edit
    else
        mode=create
    fi
    debug "${mode}: $vault"
    vv ansible-vault $mode \
        $vaultpwfiles \
        $vault
}
for VAULT in $VAULTS;do
    edit_vault $VAULT
done
