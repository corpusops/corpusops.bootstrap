#!/usr/bin/env bash
cd "$(dirname $0)"
if python -c "1" 2>/dev/null;then
    [[ -n $DEBUG ]] && echo "Python already installed"
    exit 0
fi
export NONINTERACTIVE=y
installpy() { bash ./cops_pkgmgr_install.sh python; }
c="mint|debian|ubuntu|redhat|red-hat"
if cat /etc/*-release 2>/dev/null | egrep -qi "$c";then
    installpy
else
    echo "No method to check python install"
fi
# vim:set et sts=4 ts=4 tw=80:
