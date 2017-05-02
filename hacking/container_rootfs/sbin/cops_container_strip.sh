#!/usr/bin/env bash
vv() { echo "$@" >&2;"$@"; }
COPS_ROOT=${COPS_ROOT:-/src/corpusops/corpusops.bootstrap}
[[ -e $COPS_ROOT/bin/git_pack ]] && vv $COPS_ROOT/bin/git_pack /
[[ -e /sbin/cops_container_cleanup.sh ]] && vv /sbin/cops_container_cleanup.sh
[[ -e /sbin/cops_container_snapshot.sh ]] && vv /sbin/cops_container_snapshot.sh
# vim:set et sts=4 ts=4 tw=80:
