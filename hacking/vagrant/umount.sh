#!/usr/bin/env bash
cd "$(dirname "$0")/../.."
. bin/cops_shell_common
if [ -e mountpoint/bin ];then
    vv fusermount -u mountpoint
    die_in_error "Error while umounting"
else
    log "$PWD not mounted"
fi
# vim:set et sts=4 ts=4 tw=80:
