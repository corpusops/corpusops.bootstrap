#!/usr/bin/env bash
FIND_EXCLUDES="/mnt|/HOST_(CWD|(ROOT)*FS)|.*lib/(lxc|docker).*"
detect_os() {
    # this function should be copiable in other scripts, dont use adjacent functions
    UNAME="${UNAME:-"$(uname | awk '{print tolower($1)}')"}"
    PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
    SED="sed"
    if [ "x${UNAME}" != "xlinux" ] && has_command gsed; then
        SED=gsed
    fi
    DISTRIB_CODENAME=""
    DISTRIB_ID=""
    DISTRIB_RELEASE=""
    if hash -r lsb_release >/dev/null 2>&1; then
        DISTRIB_ID=$(lsb_release -si)
        DISTRIB_CODENAME=$(lsb_release -sc)
        DISTRIB_RELEASE=$(lsb_release -sr)
    elif [ -e /etc/lsb-release ];then
        debug "No lsb_release, sourcing manually /etc/lsb-release"
        DISTRIB_ID=$(. /etc/lsb-release;echo ${DISTRIB_ID})
        DISTRIB_CODENAME=$(. /etc/lsb-release;echo ${DISTRIB_CODENAME})
        DISTRIB_RELEASE=$(. /etc/lsb-release;echo ${DISTRIB_RELEASE})
    elif [ -e /etc/os-release ];then
        DISTRIB_ID=$(. /etc/os-release;echo $ID)
        DISTRIB_CODENAME=$(. /etc/os-release;echo $VERSION)
        DISTRIB_CODENAME=$(echo $DISTRIB_CODENAME |sed -e "s/.*(\([^)]\+\))/\1/")
        DISTRIB_RELEASE=$(. /etc/os-release;echo $VERSION_ID)
    elif [ -e /etc/redhat-release ];then
        RHRELEASE=$(cat /etc/redhat-release)
        DISTRIB_CODENAME=${RHRELEASE}
        DISTRIB_RELEASE=${RHRELEASE}
        DISTRIB_ID=${RHRELEASE}
        DISTRIB_CODENAME=$(echo $DISTRIB_CODENAME |sed -e "s/.*(\([^)]\+\))/\1/")
        DISTRIB_RELEASE=$(echo $DISTRIB_RELEASE |sed -e "s/release \([0-9]\)/\1/")
        DISTRIB_ID=$(echo $DISTRIB_ID | awk '{print tolower($1)}')
    else
        if ! ( echo ${@-} | grep -q no_fail );then
            echo "unexpected case, no lsb_release" >&2
            exit 1
        fi
    fi
}
detect_os

is_docker=""
is_upstart=""

init=/sbin/init
for init in /usr/sbin/init /sbin/init; do
    if test -e $init; then
        break;
    fi
done
if $init --help | grep -iq upstart; then
    is_upstart="y"
fi
for i in /.dockerinit /.dockerenv;do
    if [ -f "${i}" ];then
        is_docker="1"
        break
    fi
done
if [ "x${is_docker}" != "x1" ] && [ "x${container-}" = "xdocker" ];then
    is_docker="1"
fi
if [ "x${is_docker}" != "x1" ] &&\
    grep -q "system.slice/docker-" /proc/1/cgroup 2>/dev/null;then
    is_docker="1"
fi

# Freeze hostile packages
FROZEN_PACKAGES="whoopsie ntp fuse grub-common grub-pc grub-pc-bin grub2-common"
if echo ${DISTRIB_ID} | egrep -iq "ubuntu|debian";then
    if [[ "${DISTRIB_RELEASE//\./}" -lt "1604" ]];then
        FROZEN_PACKAGES="${FROZEN_PACKAGES} udev"
    fi
    for i in ${FROZEN_PACKAGES}; do
        echo ${i} hold | dpkg --set-selections || /bin/true
    done
fi


# On docker, disable dhcp on main if unless we explicitly configure the image to
if [ "x${is_docker}" != "x" ];then
    # remove /dev/xconsole PIPE from lxc template
    if [ -p /dev/xconsole ];then
        rm -f /dev/xconsole
    fi
fi

# Comment out the ntpdate ifup plugin inside a container
if [ -f /etc/network/if-up.d/ntpdate ];then
    sed -re "s/^(([^#].*)|)$/#\\1/g" -i /etc/network/if-up.d/ntpdate
fi

# Disabling fstab
for i in /lib/init/fstab /etc/fstab;do
    if [ -e ${i} ];then
        sed -i -re "s/^#?(.*)/#\\1/g" "${i}" || /bin/true
    fi
done


# Pruning old logs & pids & nologin flags
rm -rf /var/run/network/* || /bin/true
rm -f /var/run/rsyslogd.pid || /bin/true
for i in /var/run/*.pid /var/run/dbus/pid /etc/nologin;do
    if [ -e "${i}" ];then
        rm -f "${i}" || /bin/true
    fi
done


# Disable rsyslog console logging
if [ -e /etc/rsyslog.d/50-default.conf ];then
    sed -i -re '/^\s*daemon.*;mail.*/ { N;N;N; s/^/#/gm }'\
        /etc/rsyslog.d/50-default.conf || /bin/true
fi

# Reacticated services that may be disabled in an earlier time
for reactivated_service in procps;do
    if [ -e "/etc/init/${reactivated_service}.conf.orig" ];then
        mv -f "/etc/init/${reactivated_service}.conf.orig" \
            "/etc/init/${reactivated_service}.conf" || /bin/true
    fi
    if [ -e "/etc/init/${reactivated_service}.override" ];then
        rm -f "${reactivated_service}.override" || /bin/true
    fi
done


# Disable harmful systemd/logind features
if [ -f /etc/systemd/logind.conf ];then
    for i in NAutoVTs ReserveVT;do
        sed -i -re "/${i}/ d" /etc/systemd/logind.conf
        echo "${i}=0">>/etc/systemd/logind.conf
    done
fi

symlink() {
    orig=${1}
    tgt=${2}
    if test -h "${tgt}" && [[ "x$(readlink -f "${tgt}")" == "x${orig}" ]]; then
        :
    else
        ln -sfv "${orig}" "${tgt}"
    fi
}

# disabling useless and harmfull services instead of deleting them
# - we must need to rely on direct file system to avoid relying on running
#   system manager process(es) (pid: 1)
# - AKA: do not activate those evil services in a container context
# - tty units (systemd) are only evil if the lock the first console
disable_service() {
    s="$1"
    # upstart
    sn=$s
    sn=$(basename $sn .unit)
    sn=$(basename $sn .socket)
    sn=$(basename $sn .target)
    sn=$(basename $sn .service)
    for i in /etc/init/${sn}*.conf;do
        if [ -e "${i}" ];then
            echo manual>"/etc/init/$(basename ${i} .conf).override" || /bin/true
            mv -f "${i}" "${i}.orig" || /bin/true
        fi
    done
    # SystemD
    for d in /lib/systemd /etc/systemd /usr/lib/systemd;do
        if [ -e /etc/systemd/system ];then
            found="x"
            for candidate in ${d}/*/${s}.service ${d}/*/${s} ${d}/*/${sn};do
                if test -e ${candidate};then
                    symlink /dev/null "/etc/systemd/system/$(basename ${candidate})"
                fi
            done
            if [ "x${found}" = "x" ];then
                symlink /dev/null "/etc/systemd/system/${s}.service"
            fi
        fi
        rm -vf "${d}/"*/*.wants/${s} || /bin/true
    done
    # SystemV
    for i in 0 1 2 3 4 5 6;do
       rm -vf /etc/rc${i}.d/*${sn} || /bin/true
    done
}

systemd_reactivated="
    systemd-update-utmp\
    systemd-update-utmp-runlevel\
    udev\
    udev-finish\
"

SERVICES="\
accounts-daemon
acpid
alsa-restore
alsa-state
alsa-store
anaconda.target
apparmor
apport
atop
autovt@
console-getty
console-setup
console-shell
container-getty@
control-alt-delete
cryptdisks-enable
cryptdisks-udev
debian-fixup
display-manager
dmesg
dns-clean
failsafe
getty@
getty-static
getty@tty1
hwclock
*initctl*
kmod-static-nodes
lvm2-lvmetad
lvm2-monitor
module
mountall-net
mountall-reboot
mountall-shell
mounted-debugfs
mounted-dev
mounted-proc
mounted-run
mounted-tmp
mounted-var
ondemand
plymouth
plymouth-halt
plymouth-kexec
plymouth-read-write
plymouth-start
plymouth-switch-root
pppd-dns
serial-getty@
setvtrgb
smartd
smartmontools
sys-kernel-config.mount
systemd-ask-password-console*
systemd-ask-password-wall*
systemd-binfmt
systemd-hwdb-update
systemd-journald-audit.socket
systemd-journal-flush
systemd-logind
systemd-machine-id-commit
systemd-modules-load
systemd-remount-fs
systemd-timesyncd
tmp.mount
*udev*
ufw
umountfs
umountroot
ureadahead
user@
vnstat"

if [ "x${is_docker}" != "x" ];then
    SERVICES="${SERVICES}
systemd-sysctl*
dev-hugepages*
sys-fs-fuse-connections*
systemd-update-utmp*"
#ifup-wait-all-auto"
fi


do_disable() {
    for s in $SERVICES;do
        disable_service "${s}"
    done
}

# Dont bail out if sort is missing
if hash -r sort >/dev/null 2>&1;then
    do_disable 2>&1 | sort -u
else
    do_disable
fi


#for i in local-fs basic.target;do
#    rm -f /lib/systemd/system/${i}.wants/* || /bin/true
#done


# Redirect console log to journald log
if [ -e /run/systemd/journal/dev-log ] && [ -e /lib/systemd/systemd ];then
    if [ -e /dev/log ];then
        rm -f /dev/log
    fi
    ln -fs /run/systemd/journal/dev-log /dev/log
fi


# Disable harmful sysctls
syscfgs="$([[ -e /etc/sysctl.conf ]] && echo /etc/sysctl.conf)"
if [ -e /etc/sysctl.d ];then
    syscfgs="${syscfgs} $(ls /etc/sysctl.d/*conf 2>/dev/null)"
fi
for syscfg in ${syscfgs};do
    # if ! grep -q corpusops-cleanup "${syscfg}";then
    #     sed -i -e "s/^/#/g" "${syscfg}" || /bin/true
    #     echo "# corpusops-cleanup" >> "${syscfg}" || /bin/true
    # fi
    for i in \
        vm.mmap_min_addr\
        fs.protected_hardlinks\
        fs.protected_symlinks\
        kernel.yama.ptrace_scope\
        kernel.kptr_restrict\
        kernel.printk;do
        sed -i -re "s/^(${i})/#\1/g" -i "${syscfg}" || /bin/true
    done
done


# If ssh keys were removed,
# Be sure to have new keypairs before sshd (re)start
ssh_keys=""
if ! find /etc/ssh/ssh_host_*_key -type f >/dev/null 2>&1;then
    ssh_keys="1"
fi
if [ -e /etc/ssh ] && [ "x${ssh_keys}" != "x" ];then
    echo "Regenerating SSHD keys" >&2
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa -b 4096 || /bin/true
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa -b 1024 || /bin/true
    ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519 || /bin/true
    ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key   -N '' -t  ecdsa  || /bin/true
fi
# ALT on debian
# if [ ! -e /etc/ssh/ssh_host_rsa_key ];then
#     dpkg-reconfigure openssh-server || /bin/true
# fi


# UID accouting is broken in lxc, breaking in turn pam_ssh login
sed -re "s/^(session.*\spam_loginuid\.so.*)/#\\1/g" -i /etc/pam.d/* || /bin/true

# If this isn't lucid, then we need to twiddle the network upstart bits :(
if [ -f /etc/network/if-up.d/upstart ] &&\
   [ ${DISTRIB_CODENAME} != "lucid" ]; then
    sed -i 's/^.*emission handled.*$/echo Emitting lo/' /etc/network/if-up.d/upstart
fi


# if we found the acl restore flag, apply !
if hash -r setfacl >/dev/null 2>&1 && test -e /acls.restore; then
    for Z in z xz; do
        if [ -e /acls.txt.$Z ]; then
            ${Z}cat /acls.txt.$Z > /acls.txt
        fi
    done
    if [ -e /acls.txt ] ;then
        cd / && setfacl --restore="/acls.txt" || /bin/true
    fi
fi

# Uber important: be sure that the notify socket is writable by everyone
# as systemd service like rsyslog notify about their state this way
# and debugging notiication failure is really hard
# dbus will also need the directory to start
if [ -e /var/run/systemd/notify ]; then
    chmod 777 /var/run/systemd/notify
fi
for i in /run/systemd/system /run/uuid;do
    if [ "x${is_upstart}" = "x" ];then
        if [ ! -d ${i} ];then mkdir -p ${i};fi
    else
        if [ "x${i}" = "x/run/systemd/system" ]; then
            if [ -d ${i} ];then
                rm -rf "${i}"
            fi
        fi
    fi
done

# search resetpassword script from wezll known places
# but default to /sbin
for RP in \
 /srv/corpusops/corpusops.bootstrap/bin/cops_reset_passwords.sh \
 /sbin/cops_reset_passwords.sh \
 ;do if [ -e "${RP}" ];then break;fi;done
# if we found the password reset flag, reset any password found
if [ -e "${RP}" ] || [[ -n "${WANT_PASSWORD_RESET}" ]]; then
    "${RP}" || /bin/true
fi
# vim:set et sts=4 ts=4 tw=80:
