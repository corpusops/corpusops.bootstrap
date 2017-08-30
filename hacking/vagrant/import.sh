#!/usr/bin/env bash
cd "$(dirname "$0")/../.."
export LOGGER_NAME=cops_vagrant
sc=bin/cops_shell_common
[[ ! -e $sc ]] && echo "missing $sc" >&2
. $sc || exit 1

usage () {
    NO_HEADER=y die '
[BOX=] \
[NO_BOX_CLEANUP=] \
Import a vagrant vm

    '"$0"' export_file
'
}
BOX=${BOX:-${1}}
parse_cli() {
    parse_cli_common "${@}"
    if [ -z "${BOX}" ];then
        die "give a box file"
    fi
    if [ ! -e ${BOX} ];then
        die "provide a valid box file"
    fi
}
parse_cli "$@"
if [ -e .vagrant ];then
    if [ "x$(find .vagrant/ -type f)" != "x" ];then
        log ".vagrant boxes exists, bailing out"
        die "..."
    fi
fi
sanitize() {
    echo $@  | sed -r\
        -e "s/[ :_éàèçù\*]//g" \
        -e "s/[ \/\\]/-/g"
}
boximportname=cops_$(sanitize $PWD)
cleanup_import_box() {
    if [[ -n "${NO_BOX_CLEANUP}" ]];then
        log "NO_BOX_CLEANUP set, skip box cleanup for ${boximportname}"
        return 0
    fi
    if vagrant box list | egrep -q "$boximportname";then
        vv vagrant box remove --force "${boximportname}"
    fi
}
vv vagrant box add --force "${boximportname}" "${BOX}"
die_in_error "vagrant box import from $BOX failed"
if [ ! -e vagrant_config.yml ];then
    echo "---">>vagrant_config.yml
fi
dcfg=$(find ~/.vagrant*/"boxes/${boximportname}" \
    -name vagrant_config.yml 2>/dev/null | head -n1)
echo $dcfg
if [[ -n "${dcfg}" ]] && [ -f "${dcfg}" ];then
    vv cp -f "${dcfg}" vagrant_config.yml
else
    echo >> vagrant_config.yml
fi
sed -i "/(BOX|BOX_URI)/d" vagrant_config.yml
cat >> vagrant_config.yml << EOF
BOX: ${boximportname}
BOX_URI: file://$(readlink -f ${BOX})
EOF
vagrant up
die_in_error "vagrant import from $BOX failed"
# we cant as the ssh key is contained inside !
# cleanup_import_box
# vim:set et sts=4 ts=4 tw=80:
