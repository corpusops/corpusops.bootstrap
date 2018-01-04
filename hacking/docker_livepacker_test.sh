#!/bin/bash
#
# Launch a container like packer would have to debug builds
#
W=$(pwd)
export LOGGER_NAME=packer_test
sc=$(dirname $(readlink -f "$0"))/../bin/cops_shell_common
[[ ! -e $sc ]] && echo "missing $sc" >&2
. "$sc" || exit 1
usage() {
    NO_HEADER=y die '
Wrapper to run a container similar to packer build
to debug the build process

 [DOCKER_EXTRA_ARGS=] \
 [DNAME=[mycontainer] \
 '"$0"' [PACKER_FILE.json]
 '
}

PACKER_FILE=${PACKER_FILE:-${1:-$(ls -1 .docker/packer/*.json|sort -rn|head -n 1)}}
grep_packer_value() { grep '"'"$1"'"' ${2-$PACKER_FILE}|awk '{print $2}'|sed -re 's/^[^"]*"|"[^"]*$//g'; }
vv() { echo "$@" >&2; "$@"; }
IMAGE_BASE=$(grep_packer_value image)
TAG_NAME=$(grep_packer_value tag_name)
PROVISION_DIR=${PROVISION_DIR:-/provision_dir}
AUTHOR=$(grep_packer_value author)
VERSION=$(grep_packer_value tag_version)
IMAGE_EP=$(grep_packer_value img_entrypoint)
ANSIBLE_FOLDER=$(grep_packer_value ansible_folder)
ANSIBLE_FOLDER="${ANSIBLE_FOLDER:-.ansible}"
ANSIBLE_VAULTS="${ANSIBLE_VAULTS:-${ANSIBLE_FOLDER}/vaults}"
ANSIBLE_PLAY=$(grep_packer_value ansible_play)
DEFAULT_VAULTS="${DEFAULT_VAULTS:-$ANSIBLE_VAULTS/default.yml $ANSIBLE_VAULTS/app.yml $ANSIBLE_VAULTS/docker.yml}"
ANSIBLE_PLAYBOOK=$(grep_packer_value ansible_playbook)
SETUP_DIR=$W/local/setup
DATA_DIR=$W/local/data
if [ ! -e $SETUP_DIR ];then vv mkdir $SETUP_DIR;fi
if [ ! -e $SETUP_DIR/reconfigure.yml ];then vv touch $SETUP_DIR/reconfigure.yml;fi
DNAME_DEFAULT="$(echo "${AUTHOR}${TAG_NAME}${VERSION}_live"|sed -re "s/_|-|\.//g")"
DNAME=${DNAME:-${DNAME_DEFAULT}}
DOCKER_EXTRA_ARGS=${DOCKER_EXTRA_ARGS-}
LOCAL_COPS_ROOT=${LOCAL_COPS_ROOT:-$W/local/corpusops.bootstrap}
COPS_ROOT=${COPS_ROOT:-/srv/corpusops/corpusops.bootstrap}
if [ -e $COPS_ROOT ];then
    COPS_ROOT=$(readlink -f $COPS_ROOT)
fi
COPS_PLAY="${COPS_PLAY:-.ansible/site.yml}"
COPS_ALTPLAY="${COPS_ALTPLAY:-.ansible/playbooks/site.yml}"

if vv docker run \
    -v $LOCAL_COPS_ROOT/bin:$COPS_ROOT/bin \
    -v $LOCAL_COPS_ROOT/hacking:$COPS_ROOT/hacking \
    -v $LOCAL_COPS_ROOT/roles/corpusops.roles:$COPS_ROOT/roles/corpusops.roles \
    -v $SETUP_DIR:/setup:ro \
    -v $DATA_DIR:/srv/projects/$TAG_NAME/data \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v $W:${PROVISION_DIR}.in:ro \
    --security-opt seccomp=unconfined \
    -e COPS_IMGVER=$VERSION \
    -e COPS_IMGTAG=$AUTHOR/$TAG_NAME:$VERSION\
    -e COPS_IMG=$AUTHOR/$TAG_NAME \
    -e COPS_IMGIMAGE=$TAG_NAME \
    -e ANSIBLE_PLAYBOOK=$ANSIBLE_PLAYBOOK \
    -e ANSIBLE_PLAY=$ANSIBLE_PLAY \
    -e ANSIBLE_FOLDER=$ANSIBLE_FOLDER \
    $DOCKER_EXTRA_ARGS \
    -d -i -t --name  ${DNAME}\
    $IMAGE_BASE $IMAGE_EP;then
    echo "Well done, connect using docker exec -ti ${DNAME} bash"
    echo "In most cases to test provison, use: "
    acmd="rsync -azv ${PROVISION_DIR}.in/ ${PROVISION_DIR}/;cd $PROVISION_DIR;$COPS_ROOT/bin/cops_apply_role -vvvv --skip-tags to_skip -e@/setup/reconfigure.yml -e cops_playbooks=$COPS_ROOT/roles/corpusops.roles/playbooks -e cops_path=$COPS_ROOT -e cops_cwd=${PROVISION_DIR}"
    for i in $DEFAULT_VAULTS;do
        if [ -e $W/$i ];then
            acmd="$acmd -e@$i"
        fi
    done
    if [ -e $COPS_ALTPLAY ];then
        echo " *           $acmd $PROVISION_DIR/$COPS_ALTPLAY"
    fi
    echo     " * [generic] $acmd $PROVISION_DIR/$COPS_PLAY"
else
    echo error
    exit 1
fi
