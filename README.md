
DISCLAIMER - ABANDONED/UNMAINTAINED CODE / DO NOT USE
=======================================================
While this repository has been inactive for some time, this formal notice, issued on **December 10, 2024**, serves as the official declaration to clarify the situation. Consequently, this repository and all associated resources (including related projects, code, documentation, and distributed packages such as Docker images, PyPI packages, etc.) are now explicitly declared **unmaintained** and **abandoned**.

I would like to remind everyone that this project’s free license has always been based on the principle that the software is provided "AS-IS", without any warranty or expectation of liability or maintenance from the maintainer.
As such, it is used solely at the user's own risk, with no warranty or liability from the maintainer, including but not limited to any damages arising from its use.

Due to the enactment of the Cyber Resilience Act (EU Regulation 2024/2847), which significantly alters the regulatory framework, including penalties of up to €15M, combined with its demands for **unpaid** and **indefinite** liability, it has become untenable for me to continue maintaining all my Open Source Projects as a natural person.
The new regulations impose personal liability risks and create an unacceptable burden, regardless of my personal situation now or in the future, particularly when the work is done voluntarily and without compensation.

**No further technical support, updates (including security patches), or maintenance, of any kind, will be provided.**

These resources may remain online, but solely for public archiving, documentation, and educational purposes.

Users are strongly advised not to use these resources in any active or production-related projects, and to seek alternative solutions that comply with the new legal requirements (EU CRA).

**Using these resources outside of these contexts is strictly prohibited and is done at your own risk.**

This project has been transfered to Makina Corpus <freesoftware@makina-corpus.com> ( https://makina-corpus.com ). This project and its associated resources, including published resources related to this project (e.g., from PyPI, Docker Hub, GitHub, etc.), may be removed starting **March 15, 2025**, especially if the CRA’s risks remain disproportionate.

# CORPUS OPS BOOTSTRAP PACKAGE

## INTRO
This packages helps to bring out a working ansible environment to bootstrap a whole modern infrastructure

## Documentation topics
- [Docs](./docs)

## Galaxy
corpusops team normally add entries to this [galaxy user](https://galaxy.ansible.com/corpusops/).

## Installing

note for OSX users: we won't install dependencies for you: you need `virtualenv` and a valid python installation.

```sh
mkdir corpusops
git clone https://github.com/corpusops/corpusops.bootstrap.git -b 4.0 corpusops/corpusops.bootstrap
corpusops/corpusops.bootstrap/bin/install.sh -l
corpusops/corpusops.bootstrap/bin/install.sh
```

It will in ./corpusops/corpusops.bootstrap:

* download prerequisites packages for your distribution
* Install a virtualenv with ansible
* Download corpusops roles & playbooks


### Note about branches and Versions

| corpusops.bootstrap | roles branch       | supported python version | bundled ansible branch    | ansible requirements   |  release year date | docker tags |
| ------------------- | ------------------ | ------------------------ | ------------------------- | -----------------------| ------------------ | ----------- |
| `4.0`               | 4.0                | **>=python-3.10**        | **2.17**                  | `>= 2.10`              | 2024  | `corpusops/ubuntu:24.04-2.17`, `corpusops/ubuntu:22.04-2.17`, `corpusops/debian:bookworm-2.17` |
| `3.0`               | 2.0                | **>=python-3.9**         | **2.14**                  | `>= 2.10`              | 2021  | `corpusops/ubuntu:latest` (ansible-2.14), `corpusops/ubuntu:22.04-2.14`, `corpusops/ubuntu:20.04-2.14` |
| `2.0`               | 2.0                | **python-3**             | **2.10**                  | `2.9,2.10`             | 2019  | `corpusops/ubuntu:22.04-2.10`, `corpusops/ubuntu:20.04-2.10`, `corpusops/ubuntu:18.04-2.10`,  `corpusops/ubuntu:22.04-2.9`, `corpusops/ubuntu:20.04-2.9`, `corpusops/ubuntu:18.04-2.9`  |
| `master`            | master             | **python-2.8**           | **2.7**                   | `2.5, 2.7`             | 2017  | `corpusops/ubuntu:20.04-2.7`, `corpusops/ubuntu:18.04-2.7`    |


### Upgrading from any branch
We provide a semi-automatic way to proceed to ``4.0`` upgrade not to break old installs, it's as simple as copying this in a terminal

```sh
# be sure to be on the latest changeset of the corpusops.bootstrap's local branch checkout
cd $corpusops_bootstrap && \
    git fetch origin && \
    ./bin/install.sh -C -b 4.0 --ansible-branch 2.17 --roles-branch 4.0 && \
    bin/install.sh -C && \
    rm -f .corpusops/*_branch
```

## Ansible notes
- It's better to use the installer (this repo, corpusops.bootstrap) that uses under the hood our [ansible fork](https://github.com/corpusops/ansible)
 which have [small fixes & divergences](https://github.com/corpusops/ansible/tree/stable-2.17/divergences)
 to [pristine ansible](https://github.com/ansible/ansible).

## badges
|  B  | S   |  B | S   |
| --- | --- | ---| --- |
| 4.0 | [![.github/workflows/cicd.yml](https://github.com/corpusops/corpusops.bootstrap/actions/workflows/cicd.yml/badge.svg?branch=4.0)](https://github.com/corpusops/corpusops.bootstrap/actions/workflows/cicd.yml) | 3.0 | [![.github/workflows/cicd.yml](https://github.com/corpusops/corpusops.bootstrap/actions/workflows/cicd.yml/badge.svg?branch=3.0)](https://github.com/corpusops/corpusops.bootstrap/actions/workflows/cicd.yml) |

## Roles
- [corpusops.roles](https://github.com/corpusops/roles)

### Ansible preconfigured playbooks helpers
- [playbooks](https://github.com/corpusops/roles/tree/master/playbooks)

### Ansible plugins roles
- [ansible_plugins](https://github.com/corpusops/roles/tree/master/ansible_plugins): collections of lookup, plugins, and filters
    - debug
    - lsb_release
    - humanlog
    - actionhelper
    - jinjarender
    - include_jinja_vars
    - saltcall

### Low level configuration roles
|  Role                                       |  Role                                       |
| ------------------------------------------- | ------------------------------------------- |
| [vars](https://github.com/corpusops/roles/tree/master/vars)                                                        |                                                                                                            |
| [localsettings_apparmor](https://github.com/corpusops/roles/tree/master/localsettings_apparmor)                    | [localsettings_apparmor_vars](https://github.com/corpusops/roles/tree/master/localsettings_apparmor_vars)          |
| [localsettings_autoupgrades](https://github.com/corpusops/roles/tree/master/localsettings_autoupgrades)            | [localsettings_autoupgrades_vars](https://github.com/corpusops/roles/tree/master/localsettings_autoupgrades_vars)  |
| [localsettings_basepkgs](https://github.com/corpusops/roles/tree/master/localsettings_basepkgs)                    | [localsettings_basepkgs_vars](https://github.com/corpusops/roles/tree/master/localsettings_basepkgs_vars)          |
| [localsettings_dns](https://github.com/corpusops/roles/tree/master/localsettings_dns)                              | [localsettings_dns_vars](https://github.com/corpusops/roles/tree/master/localsettings_dns_vars)                    |
| [localsettings_editor](https://github.com/corpusops/roles/tree/master/localsettings_editor)                        | [localsettings_editor_vars](https://github.com/corpusops/roles/tree/master/localsettings_editor_vars)              |
| [localsettings_etckeeper](https://github.com/corpusops/roles/tree/master/localsettings_etckeeper)                  | [localsettings_etckeeper_vars](https://github.com/corpusops/roles/tree/master/localsettings_etckeeper_vars)        |
| [localsettings_git](https://github.com/corpusops/roles/tree/master/localsettings_git)                              | [localsettings_git_vars](https://github.com/corpusops/roles/tree/master/localsettings_git_vars)                    |
| [localsettings_golang](https://github.com/corpusops/roles/tree/master/localsettings_golang)                        | [localsettings_golang_vars](https://github.com/corpusops/roles/tree/master/localsettings_golang_vars)              |
| [localsettings_jdk](https://github.com/corpusops/roles/tree/master/localsettings_jdk)                              | [localsettings_jdk_vars](https://github.com/corpusops/roles/tree/master/localsettings_jdk_vars)                    |
| [localsettings_locales](https://github.com/corpusops/roles/tree/master/localsettings_locales)                      | [localsettings_locales_vars](https://github.com/corpusops/roles/tree/master/localsettings_locales_vars)            |
| [localsettings_nscd](https://github.com/corpusops/roles/tree/master/localsettings_nscd)                            | [localsettings_nscd_vars](https://github.com/corpusops/roles/tree/master/localsettings_nscd_vars)                  |
| [localsettings_pkgmgr      ](https://github.com/corpusops/roles/tree/master/localsettings_pkgmgr)                  | [localsettings_pkgmgr_vars ](https://github.com/corpusops/roles/tree/master/localsettings_pkgmgr_vars)             |
| [localsettings_profile     ](https://github.com/corpusops/roles/tree/master/localsettings_profile)                 | [localsettings_profile_vars](https://github.com/corpusops/roles/tree/master/localsettings_profile_vars)            |
| [localsettings_screen      ](https://github.com/corpusops/roles/tree/master/localsettings_screen)                  | [localsettings_screen_vars ](https://github.com/corpusops/roles/tree/master/localsettings_screen_vars)             |
| [localsettings_ssh         ](https://github.com/corpusops/roles/tree/master/localsettings_ssh)                     | [localsettings_ssh_vars    ](https://github.com/corpusops/roles/tree/master/localsettings_ssh_vars)                |
| [localsettings_sudo        ](https://github.com/corpusops/roles/tree/master/localsettings_sudo)                    | [localsettings_sudo_vars   ](https://github.com/corpusops/roles/tree/master/localsettings_sudo_vars)               |
| [localsettings_sysctls     ](https://github.com/corpusops/roles/tree/master/localsettings_sysctls)                 | [localsettings_sysctls_vars](https://github.com/corpusops/roles/tree/master/localsettings_sysctls_vars)            |
| [localsettings_timezone    ](https://github.com/corpusops/roles/tree/master/localsettings_timezone)                | [localsettings_timezone_vars](https://github.com/corpusops/roles/tree/master/localsettings_timezone_vars)          |
| [localsettings_vim         ](https://github.com/corpusops/roles/tree/master/localsettings_vim)                     | [localsettings_vim_vars    ](https://github.com/corpusops/roles/tree/master/localsettings_vim_vars)                |
| [localsettings_packer         ](https://github.com/corpusops/roles/tree/master/localsettings_packer)               | [localsettings_packer_vars    ](https://github.com/corpusops/roles/tree/master/localsettings_packer_vars) |
| [localsettings_nodejs         ](https://github.com/corpusops/roles/tree/master/localsettings_nodejs)               | [localsettings_nodejs_vars    ](https://github.com/corpusops/roles/tree/master/localsettings_nodejs_vars) |

## Services configuration roles
|  Role                                       |  Role                                       |
| ------------------------------------------- | ------------------------------------------- |
| [services_base_cron](https://github.com/corpusops/roles/tree/master/services_base_cron)                     | [services_base_cron_vars](https://github.com/corpusops/roles/tree/master/services_base_cron_vars)                     |
| [services_base_ntp](https://github.com/corpusops/roles/tree/master/services_base_ntp)                       | [services_base_ntp_vars](https://github.com/corpusops/roles/tree/master/services_base_ntp_vars)                       |
| [services_base_sshd](https://github.com/corpusops/roles/tree/master/services_base_sshd)                     | [services_base_sshd_vars](https://github.com/corpusops/roles/tree/master/services_base_sshd_vars)                     |
| [services_magicbridge](https://github.com/corpusops/roles/tree/master/services_magicbridge)                 | [services_magicbridge_vars](https://github.com/corpusops/roles/tree/master/services_magicbridge_vars)                 |
| [services_misc_robotframework](https://github.com/corpusops/roles/tree/master/services_misc_robotframework) | [services_misc_robotframework_vars](https://github.com/corpusops/roles/tree/master/services_misc_robotframework_vars) |
| [services_misc_xvfb](https://github.com/corpusops/roles/tree/master/services_misc_xvfb)                     | [services_misc_xvfb_vars](https://github.com/corpusops/roles/tree/master/services_misc_xvfb_vars)                     |
| [services_virt_docker](https://github.com/corpusops/roles/tree/master/services_virt_docker)                 | [services_virt_docker_vars](https://github.com/corpusops/roles/tree/master/services_virt_docker_vars)                 |
| [services_virt_lxc](https://github.com/corpusops/roles/tree/master/services_virt_lxc)                       | [services_virt_lxc_vars](https://github.com/corpusops/roles/tree/master/services_virt_lxc_vars)                       |
| [services_virt_lxc](https://github.com/corpusops/roles/tree/master/services_http_nginx)                       |  |

## Helpers
|  Role                                                                   | role         |
| ----------------------------------------------------------------------- | ------------ |
| [corpusops.lxc_create      ](https://github.com/corpusops/roles/tree/master/lxc_create)   | [corpusops.lxc_sshauth     ](https://github.com/corpusops/roles/tree/master/lxc_sshauth) |
| [corpusops.lxc_drop        ](https://github.com/corpusops/roles/tree/master/lxc_drop)     |                                                                        |
| [corpusops.lxc_register    ](https://github.com/corpusops/roles/tree/master/lxc_register) | [corpusops.lxc_sync        ](https://github.com/corpusops/roles/tree/master/lxc_sync)    |
| [corpusops.lxc_snapshot    ](https://github.com/corpusops/roles/tree/master/lxc_snapshot) | [corpusops.lxc_vars        ](https://github.com/corpusops/roles/tree/master/lxc_vars)    |
| [corpusops.nginx_vhost    ](https://github.com/corpusops/roles/tree/master/nginx_vhost) | |
| [switch_to_systemd_resolved        ](https://github.com/corpusops/roles/tree/master/switch_to_systemd_resolved)    | [supervisor        ](https://github.com/corpusops/roles/tree/master/supervisor)    |
| [ssl_selfsigned_cert        ](https://github.com/corpusops/roles/tree/master/ssl_selfsigned_cert)    |[sshkeys        ](https://github.com/corpusops/roles/tree/master/sshkeys)    |
| [sslcerts        ](https://github.com/corpusops/roles/tree/master/sslcerts)    |                      [set_alternatives        ](https://github.com/corpusops/roles/tree/master/set_alternatives)    |
| [ssl_ca_signed_cert        ](https://github.com/corpusops/roles/tree/master/ssl_ca_signed_cert)    |  [get_secret_variable        ](https://github.com/corpusops/roles/tree/master/get_secret_variable)    |
| [ssh_synckeys        ](https://github.com/corpusops/roles/tree/master/ssh_synckeys)    |              [docker_compose_service        ](https://github.com/corpusops/roles/tree/master/docker_compose_service)    |

## DB related roles
|  Role                                                                   | role         |
| ----------------------------------------------------------------------- | ------------ |
| [mysql_db        ](https://github.com/corpusops/roles/tree/master/mysql_db)    |                                                  [postgresql_db        ](https://github.com/corpusops/roles/tree/master/postgresql_db)    |
| [mysql_harden_user        ](https://github.com/corpusops/roles/tree/master/mysql_harden_user)    |                                [postgresql_extensions        ](https://github.com/corpusops/roles/tree/master/postgresql_extensions)    |
| [mysql_role        ](https://github.com/corpusops/roles/tree/master/mysql_role)    |                                              [postgresql_install_postgis        ](https://github.com/corpusops/roles/tree/master/postgresql_install_postgis)    |
| [postgresql_dropreset_db_encoding        ](https://github.com/corpusops/roles/tree/master/postgresql_dropreset_db_encoding)    |  [postgresql_privs        ](https://github.com/corpusops/roles/tree/master/postgresql_privs)    |
| [postgresql_role        ](https://github.com/corpusops/roles/tree/master/postgresql_role)    | |

## burp (backup) related roles
|  Role                                                                   | role         |
| ----------------------------------------------------------------------- | ------------ |
| [burp_client_configuration        ](https://github.com/corpusops/roles/tree/master/burp_client_configuration)    |              [burp_fw        ](https://github.com/corpusops/roles/tree/master/burp_fw)    |
| [burp_client_configuration_vars        ](https://github.com/corpusops/roles/tree/master/burp_client_configuration_vars)    |    [burp_plugins        ](https://github.com/corpusops/roles/tree/master/burp_plugins)    |
| [burp_client_server        ](https://github.com/corpusops/roles/tree/master/burp_client_server)    |                            [burp_server_configuration        ](https://github.com/corpusops/roles/tree/master/burp_server_configuration)    |
| [burp_client_server_vars        ](https://github.com/corpusops/roles/tree/master/burp_client_server_vars)    |                  [burp_sign        ](https://github.com/corpusops/roles/tree/master/burp_sign)    |



