#!/bin/bash
#
# Launch a container like packer would have to debug builds
#
W=$(pwd)
PACKER_FILE=${PACKER_FILE:-${1:-$(ls -1 .docker/packer/*.json|sort -rn|head -n 1)}}
grep_packer_value() { grep '"'"$1"'"' ${2-$PACKER_FILE}|awk '{print $2}'|sed -re 's/^[^"]*"|"[^"]*$//g'; }
vv() { echo "$@" >&2; "$@"; }
IMAGE_BASE=$(grep_packer_value image)
TAG_NAME=$(grep_packer_value tag_name)
AUTHOR=$(grep_packer_value author)
VERSION=$(grep_packer_value tag_version)
IMAGE_EP=$(grep_packer_value img_entrypoint)
ANSIBLE_FOLDER=$(grep_packer_value ansible_folder)
ANSIBLE_PLAY=$(grep_packer_value ansible_play)
ANSIBLE_PLAYBOOK=$(grep_packer_value ansible_playbook)
SETUP_DIR=$W/local/setup
DATA_DIR=$W/local/data
if [ ! -e $SETUP_DIR ];then vv mkdir $SETUP_DIR;fi
if [ ! -e $SETUP_DIR/reconfigure.yml ];then vv touch $SETUP_DIR/reconfigure.yml;fi
DNAME=${DNAME:-${TAG_NAME}_live}
COPS_ROOT=${COPS_ROOT:-$W/local/corpusops.bootstrap}
if [ -e $COPS_ROOT ];then
    COPS_ROOT=$(readlink -f $COPS_ROOT)
fi

croot=/srv/corpusops/corpusops.bootstrap
if vv docker run \
    -v $COPS_ROOT/bin:$croot/bin \
    -v $COPS_ROOT/hacking:$croot/hacking \
    -v $COPS_ROOT/roles/corpusops.roles:$croot/roles/corpusops.roles \
    -v $SETUP_DIR:/setup:ro \
    -v $DATA_DIR:/srv/projects/$TAG_NAME/data \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v $W:/provision_dir.in:ro \
    --security-opt seccomp=unconfined \
    -e COPS_IMGVER=$VERSION \
    -e COPS_IMGTAG=$AUTHOR/$TAG_NAME:$VERSION\
    -e COPS_IMG=$AUTHOR/$TAG_NAME \
    -e COPS_IMGIMAGE=$TAG_NAME \
    -e ANSIBLE_PLAYBOOK=$ANSIBLE_PLAYBOOK \
    -e ANSIBLE_PLAY=$ANSIBLE_PLAY \
    -e ANSIBLE_FOLDER=$ANSIBLE_FOLDER \
    -d -i -t --name  ${DNAME}\
    $IMAGE_BASE $IMAGE_EP;then
    echo "Well done, connect using docker exec -ti ${DNAME} bash"
    echo "In most cases to test provison, use: rsync -azv /provision_dir.in/ /provision_dir/;/srv/corpusops/corpusops.bootstrap//bin/cops_apply_role  -vvvvvvvvv /provision_dir/.ansible/site.yml --skip-tags to_skip -e@/setup/reconfigure.yml"
else
    echo error
    exit 1
fi
