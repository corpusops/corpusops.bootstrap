#!/usr/bin/env bash
set -e

COPS_SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -e "$COPS_SCRIPTS_DIR/ansible_deploy_env" ];then
    . "$COPS_SCRIPTS_DIR/ansible_deploy_env"
fi

usage() {
    NO_HEADER=y die '
[NO_DEFAULT_VAULTS= ] \\
[PLAYBOOK= ] \\
[NO_SILENT=1 ]\\
[A_INVENTORY=.ansible/inventory_foo ] \\
    '$0' [$@]

Call ansible-playbook with all ansible variables and vaults (variables files) preseted.
   - PLAYBOOK, vaults & A_INVENTORY are normally automatically setted up
     depending on the A_ENV_NAME variable
-
    PLAYBOOY=.ansible/playbooks/foo.yml \\
        '$0'
    -> Will append automatically corpusops related vars based on \$A_ENV_NAME
-
    '$0' .ansible/playbooks/foo.yml
    -> Will append automatically corpusops related vars based on \$A_ENV_NAME
-
    '$0' -i foobar .ansible/playbooks/foo.yml
    -> Will execute ansible-playbook as-is
-
    NO_DEFAULT_VAULTS=1 '$0' .ansible/playbooks/foo.yml
    -> Will execute ansible-playbook as-is

'
}


parse_cli $@


if [[ -z "$PLAYBOOK" ]] && [[ -z "$@" ]];then
    die "Either set \$PLAYBOOK var or give arguments to $0"
fi

set_core_variables

launchlog="$A_LAUNCH_CMD ${@}"

if [[ -n "${A_DRY_RUN}" ]];then
    die_ 0 "Would have run $launchlog"
else
    if [[ -z $NONINTERACTIVE ]];then
        printf "Do you really want to launch: $launchlog\n[Y/N] ?" >&2
        while read i;do
            if echo $i | egrep -iq "^(y|yes|oui|o)"
            then break
            else die_ 16 "aborting"
            fi
        done
    fi
fi

if [[ -n "${@}" ]];then
    $A_LAUNCH_CMD "${@}"
else
    $A_LAUNCH_CMD
fi
ret=$?
exit $ret
