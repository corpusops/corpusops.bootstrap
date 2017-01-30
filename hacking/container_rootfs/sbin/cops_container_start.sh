#!/usr/bin/env bash
# run on lxc intialisation to make room for sanitisations...
export PATH=${PATH}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games


# BE sure to have SHM mounted, if possible
if [ "x$(mount|awk '{print $3}'|grep -E "^/dev/shm"|wc -l|sed -e "s/ //g")" = "x0" ];then
    mount -t tmpfs none /dev/shm || /bin/true
fi

# Run the cleanup script
if [ -f /sbin/cops_container_cleanup.sh ];then
    /sbin/cops_container_cleanup.sh &2>/dev/null || /bin/true
fi


# upstart voodoo, be sure upstart goes along his lifecycle
if [ "x${1}" = "xupstart" ];then
    /sbin/initctl emit started JOB=console --no-wait
fi

# Make sure utmp is in place
touch /var/run/utmp || /bin/true
chown root:utmp /var/run/utmp || /bin/true
chmod 664 /var/run/utmp || /bin/true


# upstart voodoo, be sure upstart finishes to go along his lifecycle
if [ "x${1}" = "xupstart" ];then
    for j in;do
        for l in waiting starting pre-start spawned post-start running;do
            /sbin/initctl emit --no-wait $l JOB=$j || /bin/true
        done
    done
    /sbin/initctl emit --no-wait container CONTAINER=lxc || /bin/true
    for j in \
        mounting mounted all-swaps filesystem virtual-filesystems\
        net-device-up local-filesystems remote-filesystems;do
        /sbin/initctl emit --no-wait $j || /bin/true
    done
    service container-detect restart || /bin/true
    service rc-sysinit start || /bin/true
fi
# be sure to ret=0
/bin/true
# vim:set et sts=4 ts=4 tw=80:
