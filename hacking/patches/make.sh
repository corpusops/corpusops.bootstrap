#!/usr/bin/env bash
# python/test/support patch for docker ipv6 friendlyness
# to update patches
# place relevant distribs patchs and redo
# like the origin diffs (global except before the if)
set -x
cd $(dirname $0)
ret=$?
dop() {
    diff -Nur old/$f new/$f > $p.diff
}
dorhp() {
    diff -Nur oldrh/$f newrh/$f > $p.rh.diff
}

mkd() { if [ ! -e $1 ];then  mkdir -p $1;fi; }

mkd new/usr/lib/python2/test
mkd old/usr/lib/python2/test
mkd new/usr/lib/python3/test/support
mkd old/usr/lib/python3/test/support
mkd newrh/usr/lib/python2/test
mkd oldrh/usr/lib/python2/test
mkd newrh/usr/lib/python3/test/support
mkd oldrh/usr/lib/python3/test/support


p=python2
f=usr/lib/$p
dop
dorhp
p=python3
f=usr/lib/$p
dop
dorhp
# vim:set et sts=4 ts=4 tw=80:
