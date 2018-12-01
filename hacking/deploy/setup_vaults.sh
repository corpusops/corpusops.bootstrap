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
or
A_ENV_NAME="foo" CORPUSOPS_VAULT_PASSWORD="verysecret" \\
    '$0'
or
A_ENV_NAME="foo bar" CORPUSOPS_VAULT_PASSWORD="verysecret" \\
    '$0'

Setup ansible vault password files based on environment variables
'
}


parse_cli $@
default_vault="$DEFAULT_SECRET_VAULT_PREFIX._default_"

debug "VAULT_PASSWORD_VARIABLES_PREFIX: $VAULT_PASSWORD_VARIABLES_PREFIX"
if [[ -n ${SKIP_VAULT_PASSWORD_FILES_SETUP-} ]];then
    echo "-> Skip ansible vault password files setup" >&2
    exit 0
fi

if [[ -z $SECRET_VAULT_PREFIX ]];then
    log "Set \$SECRET_VAULT_PREFIX or . .ansible/scripts/ansible_deploy_env"
    exit 1
fi

# If we defined A_ENV_NAME(s) and CORPUSOPS_VAULT_PASSWORD
#   Define each env name found, and the default password
setup_vault_vars() {
    local a_env_name=$1
    shift
    if [[ -n $CORPUSOPS_VAULT_PASSWORD ]];then
        vault_var="CORPUSOPS_VAULT_PASSWORD_$(echo $a_env_name)"
        val="$(eval "echo \$$vault_var")"
        if [[ -z $val ]];then
            debug " -> Exporting new password for env: $a_env_name"
            eval "export $vault_var=$CORPUSOPS_VAULT_PASSWORD"
        fi
    fi
}
if [[ -n $A_ENV_NAME ]];then
    setup_vault_vars $A_ENV_NAME
fi
if [[ -n $A_ENV_NAMES ]];then
    for i in $A_ENV_NAMES;do setup_vault_vars $i;done
fi
if [[ -n $CORPUSOPS_VAULT_PASSWORD ]];then setup_vault_vars _default_;fi

# Setup ansible vault password files if any (via gitlab secret variable)
# from each found CORPUSOPS_VAULT_PASSWORD_XXX
export VAULT_VARS=$( printenv \
 | egrep -oe "^${VAULT_PASSWORD_VARIABLES_PREFIX}([a-zA-Z0-9]+|_default_)=" \
 | sed -e "s/=$//g"|awk '!seen[$0]++')

debug "VAULT_VARS: $( echo $VAULT_VARS )"

# We set the A_ENV_NAME password (resp. specific and then default to A_VAULT_PASSWORD_FOR_ALL)

for vault_var in $VAULT_VARS;do
    vault_name="$(echo $vault_var \
        | awk -F "${VAULT_PASSWORD_VARIABLES_PREFIX}" '{print $2}')"
    val="$(eval "echo \$$vault_var")"
    f="$SECRET_VAULT_PREFIX.$vault_name"
    log "Setup $vault_name vault password file: (${f//._default_/})"
    if [[ -n "$val" ]];then
        if ( echo "$f" | egrep -q "/" )then
            vaultsfolder="$(dirname $f)"
            if [ ! -e "$vaultf" ];then
                mkdir -p "$vaultsfolder"
            fi
        fi
        echo "$val" > "$f"
        chmod 600 "$f"
        if [ -e "$default_vault" ];then
            mv "$default_vault" "$DEFAULT_SECRET_VAULT_PREFIX"
        fi
    fi
done
