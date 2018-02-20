#!/usr/bin/env bash

COPS_SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -e "$COPS_SCRIPTS_DIR/ansible_deploy_env" ];then
    . "$COPS_SCRIPTS_DIR/ansible_deploy_env"
fi

usage() {
    NO_HEADER=y die '
[NO_DEFAULT_VAULTS= ] \\
[PLAYBOOK= ] \\
[QUIET=1 ]\\
[NO_SILENT= ]\\
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
- NO_SILENT= will make the call run without output unless an error occurs
- QUIET= will make the call not output the underlying ansible call log
-
    NO_DEFAULT_VAULTS=1 '$0' .ansible/playbooks/foo.yml
    -> Will execute ansible-playbook as-is

'
}

parse_cli $@
if [ -z $TMPPLAYBOOK ];then
    TMPPLAYBOOK=$(mktemp)
fi
[[ -z ${ROLES-} ]] && die no roles
cat > "$TMPPLAYBOOK" << EOF
---
- hosts: [all]
  roles:
EOF
for i in ${ROLES-};do
    echo "    - \"$i\"" >> "$TMPPLAYBOOK"
done
log "Running:"
cat $TMPPLAYBOOK
log
$COPS_SCRIPTS_DIR/call_ansible.sh "$@" $TMPPLAYBOOK
ret=$?
if [ -e "$fic" ];then rm -f "$fic";fi
if [[ -z ${NO_SILENT} ]] && [[ -z $QUIET ]] && [[ "$ret" != "0" ]];then
    warn "Not zero exit code: $ret"
fi
exit $ret
