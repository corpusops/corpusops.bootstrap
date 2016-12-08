# CORPUS OPS BOOTSTRAP PACKAGE

## INTRO
This packages helps to bring out a working ansible environment to boostrap
a whole modern infrastructure


## Installing

```$

mkdir corpusops
git clone https://github.com/corpusops/corpusops.bootstrap.git corpusops/corpusops.bootstrap
corpusops/corpusops.bootstrap/bin/install.sh -l
corpusops/corpusops.bootstrap/bin/install.sh

```

It will in ./corpusops/corpusops.bootstrap:

* download prerequisites packages for your distribution
* Install a virtualenv with ansible
* Download corpusops roles & playbooks

## badges

|  Branch | TravisBuild                                                                                                                                                          |
| ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| master  | [![Build Status master  Branch](https://travis-ci.org/corpusops/corpusops.bootstrap.svg?branch=master)](https://travis-ci.org/corpusops/corpusops.bootstrap/badges)  |
| working | [![Build Status WORKING Branch](https://travis-ci.org/corpusops/corpusops.bootstrap.svg?branch=working)](https://travis-ci.org/corpusops/corpusops.bootstrap/badges) |

## Roles badges

|  Role                                       | Status                                                                                                                                                          |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| corpusops.debug                             | [![Build Status master  Branch](https://travis-ci.org/corpusops/debug.svg?branch=master)](https://travis-ci.org/corpusops/debug/badges)
| corpusops.humanlog                          | [![Build Status master  Branch](https://travis-ci.org/corpusops/humanlog.svg?branch=master)](https://travis-ci.org/corpusops/humanlog/badges)
| corpusops.include_jinja_vars                | [![Build Status master  Branch](https://travis-ci.org/corpusops/include_jinja_vars.svg?branch=master)](https://travis-ci.org/corpusops/include_jinja_vars/badges)
| corpusops.vars                              | [![Build Status master  Branch](https://travis-ci.org/corpusops/vars.svg?branch=master)](https://travis-ci.org/corpusops/vars/badges)
| corpusops.localsettings_apparmor            | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_apparmor.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_apparmor/badges)
| corpusops.localsettings_apparmor_vars       | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_apparmor_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_apparmor_vars/badges)
| corpusops.localsettings_autoupgrades        | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_autoupgrades.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_autoupgrades/badges)
| corpusops.localsettings_autoupgrades_vars   | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_autoupgrades_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_autoupgrades_vars/badges)
| corpusops.localsettings_basepkgs            | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_basepkgs.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_basepkgs/badges)
| corpusops.localsettings_basepkgs_vars       | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_basepkgs_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_basepkgs_vars/badges)
| corpusops.localsettings_dns                 | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_dns.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_dns/badges)
| corpusops.localsettings_dns_vars            | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_dns_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_dns_vars/badges)
| corpusops.localsettings_editor              | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_editor.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_editor/badges)
| corpusops.localsettings_editor_vars         | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_editor_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_editor_vars/badges)
| corpusops.localsettings_etckeeper           | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_etckeeper.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_etckeeper/badges)
| corpusops.localsettings_etckeeper_vars      | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_etckeeper_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_etckeeper_vars/badges)
| corpusops.localsettings_git                 | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_git.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_git/badges)
| corpusops.localsettings_git_vars            | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_git_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_git_vars/badges)
| corpusops.localsettings_golang              | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_golang.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_golang/badges)
| corpusops.localsettings_golang_vars         | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_golang_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_golang_vars/badges)
| corpusops.localsettings_jdk                 | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_jdk.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_jdk/badges)
| corpusops.localsettings_jdk_vars            | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_jdk_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_jdk_vars/badges)
| corpusops.localsettings_locales             | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_locales.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_locales/badges)
| corpusops.localsettings_locales_vars        | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_locales_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_locales_vars/badges)
| corpusops.localsettings_nscd                | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_nscd.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_nscd/badges)
| corpusops.localsettings_nscd_vars           | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_nscd_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_nscd_vars/badges)
| corpusops.localsettings_pkgmgr              | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_pkgmgr.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_pkgmgr/badges)
| corpusops.localsettings_pkgmgr_vars         | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_pkgmgr_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_pkgmgr_vars/badges)
| corpusops.localsettings_profile             | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_profile.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_profile/badges)
| corpusops.localsettings_profile_vars        | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_profile_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_profile_vars/badges)
| corpusops.localsettings_screen              | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_screen.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_screen/badges)
| corpusops.localsettings_screen_vars         | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_screen_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_screen_vars/badges)
| corpusops.localsettings_ssh                 | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_ssh.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_ssh/badges)
| corpusops.localsettings_ssh_vars            | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_ssh_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_ssh_vars/badges)
| corpusops.localsettings_sudo                | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_sudo.svg?branch=master)](https://travis-ci.org/corpusops/corpusops.bootstrap/badges)
| corpusops.localsettings_sudo_vars           | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_sudo_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_sudo_vars/badges)
| corpusops.localsettings_sysctls             | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_sysctls.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_sysctls/badges)
| corpusops.localsettings_sysctls_vars        | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_sysctls_vars.svg?branch=master)](https://travis-ci.org/corpusops/corpusops.bootstrap/badges)
| corpusops.localsettings_vim                 | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_vim.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_vim/badges)
| corpusops.localsettings_vim_vars            | [![Build Status master  Branch](https://travis-ci.org/corpusops/localsettings_vim_vars.svg?branch=master)](https://travis-ci.org/corpusops/localsettings_vim_vars/badges)
| corpusops.saltcall                          | [![Build Status master  Branch](https://travis-ci.org/corpusops/saltcall.svg?branch=master)](https://travis-ci.org/corpusops/saltcall/badges)
| corpusops.services_base_cron                | [![Build Status master  Branch](https://travis-ci.org/corpusops/services_base_cron.svg?branch=master)](https://travis-ci.org/corpusops/services_base_cron/badges)
| corpusops.services_base_cron_vars           | [![Build Status master  Branch](https://travis-ci.org/corpusops/services_base_cron_vars.svg?branch=master)](https://travis-ci.org/corpusops/services_base_cron_vars/badges)
| corpusops.services_base_ntp                 | [![Build Status master  Branch](https://travis-ci.org/corpusops/services_base_ntp.svg?branch=master)](https://travis-ci.org/corpusops/services_base_ntp/badges)
| corpusops.services_base_ntp_vars            | [![Build Status master  Branch](https://travis-ci.org/corpusops/services_base_ntp_vars.svg?branch=master)](https://travis-ci.org/corpusops/services_base_ntp_vars/badges)
| corpusops.services_base_sshd                | [![Build Status master  Branch](https://travis-ci.org/corpusops/services_base_sshd.svg?branch=master)](https://travis-ci.org/corpusops/services_base_sshd/badges)
| corpusops.services_base_sshd_vars           | [![Build Status master  Branch](https://travis-ci.org/corpusops/services_base_sshd_vars.svg?branch=master)](https://travis-ci.org/corpusops/services_base_sshd_vars/badges)
| corpusops.services_virt_docker              | [![Build Status master  Branch](https://travis-ci.org/corpusops/services_virt_docker.svg?branch=master)](https://travis-ci.org/corpusops/services_virt_docker/badges)
| corpusops.services_virt_docker_vars         | [![Build Status master  Branch](https://travis-ci.org/corpusops/services_virt_docker_vars.svg?branch=master)](https://travis-ci.org/corpusops/services_virt_docker_vars/badges)



