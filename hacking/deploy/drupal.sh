#!/usr/bin/env bash
shopt -s extglob
set -e
DEBUG=${DEBUG-}
VERBOSE=${VERBOSE-${DEBUG}}
if [[ -n ${DEBUG-} ]] ;then
    set -x
fi
if [[ -n ${VERBOSE-} ]] ;then
    ANSIBLE_ARGS="$ANSIBLE_ARGS -vvvvv"
fi
W=$(pwd)
action=${1}
if [[ -n ${@-} ]];then shift;fi
cd "$W"
. local/corpusops.bootstrap/hacking/shell_glue
actions="@(db|full|minimal|code_and_fpm|solr|nginx|nginx_full)"
export CUR_BRANCH=$(get_git_branch)
export A_ENV_NAME=${A_ENV_NAME:-${CUR_BRANCH}}
export PROJECT_TYPE=drupal
export ANSIBLE_ARGS=${ANSIBLE_ARGS-}
### code & vhost
deploy_solr() {
    .ansible/scripts/call_ansible.sh $ANSIBLE_ARGS \
        .ansible/playbooks/solr.yml "$@"
}
deploy_db() {
    .ansible/scripts/call_ansible.sh $ANSIBLE_ARGS \
        .ansible/playbooks/db.yml "$@"
}
### code & vhost
deploy_minimal() {
    .ansible/scripts/call_ansible.sh $ANSIBLE_ARGS \
        -e "{only_steps: true,
             cops_${PROJECT_TYPE}_s_users: false,
             cops_${PROJECT_TYPE}_lifecycle_app_push_code: true,
             cops_${PROJECT_TYPE}_s_maintenance_off: false,
             cops_${PROJECT_TYPE}_s_maintenance_on: false,
             cops_${PROJECT_TYPE}_s_reverse_proxy_reload: true,
             cops_${PROJECT_TYPE}_s_setup_composer: true,
             cops_${PROJECT_TYPE}_s_workers: true,
             cops_${PROJECT_TYPE}_s_end_fixperms: true,
             cops_${PROJECT_TYPE}_s_setup_configs: true}" \
        .ansible/playbooks/app.yml "$@"
}
### code vhost & fpm
deploy_full() {
    .ansible/scripts/call_ansible.sh $ANSIBLE_ARGS .ansible/playbooks/app.yml "$@"
}
### vhost
deploy_nginx_full() {
    .ansible/scripts/call_ansible.sh $ANSIBLE_ARGS \
        -e "{only_steps: true,
             cops_${PROJECT_TYPE}_s_users: false,
             cops_${PROJECT_TYPE}_s_setup_reverse_proxy: true,
             cops_${PROJECT_TYPE}_s_reverse_proxy: true}" \
        .ansible/playbooks/app.yml "$@"
}
deploy_nginx() {
    .ansible/scripts/call_ansible.sh $ANSIBLE_ARGS \
        -e "{only_steps: true,
             cops_${PROJECT_TYPE}_s_users: false,
             cops_${PROJECT_TYPE}_s_setup_reverse_proxy: true,
             cops_${PROJECT_TYPE}_s_reverse_proxy_reload: true}" \
        .ansible/playbooks/app.yml "$@"
}
### code vhost & fpm
deploy_code_and_fpm() {
    .ansible/scripts/call_ansible.sh $ANSIBLE_ARGS \
        -e "{only_steps: true,
             cops_${PROJECT_TYPE}_s_users: false,
             cops_${PROJECT_TYPE}_lifecycle_app_push_code: true,
             cops_${PROJECT_TYPE}_s_maintenance_off: false,
             cops_${PROJECT_TYPE}_s_maintenance_on: false,
             cops_${PROJECT_TYPE}_s_setup_reverse_proxy: true,
             cops_${PROJECT_TYPE}_s_reverse_proxy_reload: true,
             cops_${PROJECT_TYPE}_s_workers: true,
             cops_${PROJECT_TYPE}_s_setup_composer: true,
             cops_${PROJECT_TYPE}_s_setup_fpm: true,
             cops_${PROJECT_TYPE}_s_end_fixperms: true,
             cops_${PROJECT_TYPE}_s_setup_configs: true}" \
        .ansible/playbooks/app.yml "$@"
}
usage() { echo "$0 $actions \$@"; }
case $action in $actions)deploy_${action} "$@";;*) usage;;esac
exit $?
