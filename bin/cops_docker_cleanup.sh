#!/usr/bin/env bash
# try to cleanup most of the dangling containers and images

DATA_FILTER="mysql|postgresql|pgsql|redis|mongodb|storage|backup"

# remove intermediates containers
# and retain data containers
cids="
$( \
    docker ps -a --no-trunc \
    | grep  Exited \
    | egrep "sh -c '((.*apt-get ((install|remove )|(-y (install|remove))))|echo|#\(nop|.*step_rev.*)" \
    | awk '{print $1}' )
$( \
    docker ps -a --no-trunc \
    | grep  Exited \
    | grep '"bash"'\
    | egrep -v "$DATA_FILTER"\
    | awk '{print $1}' )
"

# remove old images
# remove cops test images
imgids="
$( \
    docker images --filter dangling=true -q )
$( \
    docker images -a|grep copstest|awk '{print $3}' )
"

while read i;do
    if [[ -n "${i}" ]];then
        echo "Remove container: $i" >&2
        docker rm -f $i >/dev/null
    fi
done < <(echo ${cids}|xargs -n1|sort -u)

while read i;do
    if [[ -n "${i}" ]];then
        echo "Remove image: $i" >&2
        docker rmi $i >/dev/null
    fi
done < <(echo ${imgids}|xargs -n1|sort -u)
# vim:set et sts=4 ts=4 tw=80:
