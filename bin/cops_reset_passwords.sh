#!/usr/bin/env bash
set +e
# if we found the password reset flag, reset any password found
# in shadow entries back to a random value

MARKER="/passwords.reset"

if [[ -n "${WANT_PASSWORD_RESET}" ]];then
    touch "${MARKER}"
fi

unflag=""
if test -e "${MARKER}" && hash -r chpasswd >/dev/null 2>&1;then
    for user in $(cat /etc/shadow | awk -F: '{print $1}');do
        oldpw=$(getent shadow ${user} | awk -F: '{print $2}')
        if [ "x${oldpw}" != "x" ] &&\
            [ "x${oldpw}" != "x*" ] &&\
            [ "x${oldpw}" != "x!" ] &&\
            [ "x${oldpw}" != "x!!" ] &&\
            [ "x${oldpw}" != "xNC" ] &&\
            [ "x${oldpw}" != "xLK" ];then
            pw=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-32};echo)
            echo "Resetting password for ${user}" >&2
            echo "${user}:${pw}" | chpasswd
            if [ "x${?}" != "x0" ];then
                unflag="n"
            fi
        fi
    done
    if [[ -z "${unflag}" ]] && [ -e "${MARKER}" ];then
        rm -fv "${MARKER}"
    fi
else
    echo "${MARKER} not found, if you really want to reset all user passwords,"
    echo "do one of:" >&2
    echo "- touch ${MARKER}" >&2
    echo "- export WANT_PASSWORD_RESET=y" >&2
fi
# vim:set et sts=4 ts=4 tw=80:
