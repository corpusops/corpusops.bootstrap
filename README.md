# CORPUS OPS BOOTSTRAP PACKAGE

## INTRO
This packages helps to bring out a working ansible environment to boostrap
a whole modern infrastructure


## Galaxy
corpusops team normally add entries to this [galaxy user](https://galaxy.ansible.com/corpusops/).

## Installing

```

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

|  Branch                                                             | TravisBuild                                                                                                                                                          |
| ------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| master                                                              | [![Build Status master  Branch](https://travis-ci.org/corpusops/corpusops.bootstrap.svg?branch=master)](https://travis-ci.org/corpusops/corpusops.bootstrap)         |

## Roles
- [corpusops.roles](https://github.com/corpusops/roles)  -> [![Build Status master  Branch](https://travis-ci.org/corpusops/roles.svg?branch=master)](https://travis-ci.org/corpusops/roles)

### Ansible plugins roles

|  Role                                       | Role                                                                                                          |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| [corpusops.debug](https://github.com/corpusops/roles/tree/master/debug)                               | [corpusops.lsb_release ](https://github.com/corpusops/roles/tree/master/lsb_release)    |
| [corpusops.humanlog](https://github.com/corpusops/roles/tree/master/humanlog)                         | [corpusops.actionhelper](https://github.com/corpusops/roles/tree/master/actionhelper)   |
| [corpusops.include_jinja_vars](https://github.com/corpusops/roles/tree/master/include_jinja_vars)     | [corpusops.saltcall    ](https://github.com/corpusops/roles/tree/master/saltcall)       |
| [corpusops.ansible_plugins](https://github.com/corpusops/roles/tree/master/ansible_plugins)           |

### Low level configuration roles
|  Role                                       |  Role                                       |
| ------------------------------------------- | ------------------------------------------- |
| [corpusops.vars](https://github.com/corpusops/roles/tree/master/vars)                                                        |                                                                                                            |
| [corpusops.localsettings_apparmor](https://github.com/corpusops/roles/tree/master/localsettings_apparmor)                    | [corpusops.localsettings_apparmor_vars](https://github.com/corpusops/roles/tree/master/localsettings_apparmor_vars)          |
| [corpusops.localsettings_autoupgrades](https://github.com/corpusops/roles/tree/master/localsettings_autoupgrades)            | [corpusops.localsettings_autoupgrades_vars](https://github.com/corpusops/roles/tree/master/localsettings_autoupgrades_vars)  |
| [corpusops.localsettings_basepkgs](https://github.com/corpusops/roles/tree/master/localsettings_basepkgs)                    | [corpusops.localsettings_basepkgs_vars](https://github.com/corpusops/roles/tree/master/localsettings_basepkgs_vars)          |
| [corpusops.localsettings_dns](https://github.com/corpusops/roles/tree/master/localsettings_dns)                              | [corpusops.localsettings_dns_vars](https://github.com/corpusops/roles/tree/master/localsettings_dns_vars)                    |
| [corpusops.localsettings_editor](https://github.com/corpusops/roles/tree/master/localsettings_editor)                        | [corpusops.localsettings_editor_vars](https://github.com/corpusops/roles/tree/master/localsettings_editor_vars)              |
| [corpusops.localsettings_etckeeper](https://github.com/corpusops/roles/tree/master/localsettings_etckeeper)                  | [corpusops.localsettings_etckeeper_vars](https://github.com/corpusops/roles/tree/master/localsettings_etckeeper_vars)        |
| [corpusops.localsettings_git](https://github.com/corpusops/roles/tree/master/localsettings_git)                              | [corpusops.localsettings_git_vars](https://github.com/corpusops/roles/tree/master/localsettings_git_vars)                    |
| [corpusops.localsettings_golang](https://github.com/corpusops/roles/tree/master/localsettings_golang)                        | [corpusops.localsettings_golang_vars](https://github.com/corpusops/roles/tree/master/localsettings_golang_vars)              |
| [corpusops.localsettings_jdk](https://github.com/corpusops/roles/tree/master/localsettings_jdk)                              | [corpusops.localsettings_jdk_vars](https://github.com/corpusops/roles/tree/master/localsettings_jdk_vars)                    |
| [corpusops.localsettings_locales](https://github.com/corpusops/roles/tree/master/localsettings_locales)                      | [corpusops.localsettings_locales_vars](https://github.com/corpusops/roles/tree/master/localsettings_locales_vars)            |
| [corpusops.localsettings_nscd](https://github.com/corpusops/roles/tree/master/localsettings_nscd)                            | [corpusops.localsettings_nscd_vars](https://github.com/corpusops/roles/tree/master/localsettings_nscd_vars)                  |
| [corpusops.localsettings_pkgmgr      ](https://github.com/corpusops/roles/tree/master/localsettings_pkgmgr)                  | [corpusops.localsettings_pkgmgr_vars ](https://github.com/corpusops/roles/tree/master/localsettings_pkgmgr_vars)             |
| [corpusops.localsettings_profile     ](https://github.com/corpusops/roles/tree/master/localsettings_profile)                 | [corpusops.localsettings_profile_vars](https://github.com/corpusops/roles/tree/master/localsettings_profile_vars)            |
| [corpusops.localsettings_screen      ](https://github.com/corpusops/roles/tree/master/localsettings_screen)                  | [corpusops.localsettings_screen_vars ](https://github.com/corpusops/roles/tree/master/localsettings_screen_vars)             |
| [corpusops.localsettings_ssh         ](https://github.com/corpusops/roles/tree/master/localsettings_ssh)                     | [corpusops.localsettings_ssh_vars    ](https://github.com/corpusops/roles/tree/master/localsettings_ssh_vars)                |
| [corpusops.localsettings_sudo        ](https://github.com/corpusops/roles/tree/master/localsettings_sudo)                    | [corpusops.localsettings_sudo_vars   ](https://github.com/corpusops/roles/tree/master/localsettings_sudo_vars)               |
| [corpusops.localsettings_sysctls     ](https://github.com/corpusops/roles/tree/master/localsettings_sysctls)                 | [corpusops.localsettings_sysctls_vars](https://github.com/corpusops/roles/tree/master/localsettings_sysctls_vars)            |
| [corpusops.localsettings_timezone    ](https://github.com/corpusops/roles/tree/master/localsettings_timezone)                | [corpusops.localsettings_timezone_vars](https://github.com/corpusops/roles/tree/master/localsettings_timezone_vars)          |
| [corpusops.localsettings_vim         ](https://github.com/corpusops/roles/tree/master/localsettings_vim)                     | [corpusops.localsettings_vim_vars    ](https://github.com/corpusops/roles/tree/master/localsettings_vim_vars)                |
| [corpusops.localsettings_packer         ](https://github.com/corpusops/roles/tree/master/localsettings_packer)                     | [corpusops.localsettings_packer_vars    ](https://github.com/corpusops/roles/tree/master/localsettings_packer_vars)                |
| [corpusops.localsettings_nodejs         ](https://github.com/corpusops/roles/tree/master/localsettings_nodejs)                     | [corpusops.localsettings_nodejs_vars    ](https://github.com/corpusops/roles/tree/master/localsettings_nodejs_vars)                |

## Services configuration roles
|  Role                                       |  Role                                       |
| ------------------------------------------- | ------------------------------------------- |
| [corpusops.services_base_cron](https://github.com/corpusops/roles/tree/master/services_base_cron)                     | [corpusops.services_base_cron_vars](https://github.com/corpusops/roles/tree/master/services_base_cron_vars)                     |
| [corpusops.services_base_ntp](https://github.com/corpusops/roles/tree/master/services_base_ntp)                       | [corpusops.services_base_ntp_vars](https://github.com/corpusops/roles/tree/master/services_base_ntp_vars)                       |
| [corpusops.services_base_sshd](https://github.com/corpusops/roles/tree/master/services_base_sshd)                     | [corpusops.services_base_sshd_vars](https://github.com/corpusops/roles/tree/master/services_base_sshd_vars)                     |
| [corpusops.services_magicbridge](https://github.com/corpusops/roles/tree/master/services_magicbridge)                 | [corpusops.services_magicbridge_vars](https://github.com/corpusops/roles/tree/master/services_magicbridge_vars)                 |
| [corpusops.services_misc_robotframework](https://github.com/corpusops/roles/tree/master/services_misc_robotframework) | [corpusops.services_misc_robotframework_vars](https://github.com/corpusops/roles/tree/master/services_misc_robotframework_vars) |
| [corpusops.services_misc_xvfb](https://github.com/corpusops/roles/tree/master/services_misc_xvfb)                     | [corpusops.services_misc_xvfb_vars](https://github.com/corpusops/roles/tree/master/services_misc_xvfb_vars)                     |
| [corpusops.services_virt_docker](https://github.com/corpusops/roles/tree/master/services_virt_docker)                 | [corpusops.services_virt_docker_vars](https://github.com/corpusops/roles/tree/master/services_virt_docker_vars)                 |
| [corpusops.services_virt_lxc](https://github.com/corpusops/roles/tree/master/services_virt_lxc)                       | [corpusops.services_virt_lxc_vars](https://github.com/corpusops/roles/tree/master/services_virt_lxc_vars)                       |


## Helpers
|  Role                                                                   | role         |
| ----------------------------------------------------------------------- | ------------ |
| [corpusops.lxc_create      ](https://github.com/corpusops/lxc_create)   | [corpusops.lxc_sshauth     ](https://github.com/corpusops/lxc_sshauth) |
| [corpusops.lxc_drop        ](https://github.com/corpusops/lxc_drop)     |                                                                        |
| [corpusops.lxc_register    ](https://github.com/corpusops/lxc_register) | [corpusops.lxc_sync        ](https://github.com/corpusops/lxc_sync)    |
| [corpusops.lxc_snapshot    ](https://github.com/corpusops/lxc_snapshot) | [corpusops.lxc_vars        ](https://github.com/corpusops/lxc_vars)    |

