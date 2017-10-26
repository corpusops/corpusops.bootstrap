# Generic Vagrant setup for a corpusops compatible VM
- Generic multibox ansible (corpusops based) vagrant setup framework
- Your localhost is the (ansible) master of the vagrant cluster !

## needed vagrant plugins
- Run this command before any provisionning
```sh
vagrant plugins install vagrant-share vagrant-vbguest
vagrant plugins update
```

## vagrant_config.yml
- This file created in your top repository can override any default setting.
- Thje vagrantfile is really dynamic, and most of the behavior won't need a modification in it, but just a knob in the ``vagrant_config.yml`` file.

### CLUSTER_NUM is the mostly the only variable you need to setup on multiple corpusops setups
- default is 1
- This control various settings and should be unique per VM & HOST as
  it controls the private network subnet (192.168.XXX).
- When you want to configure change it, ``$EDITOR vagrant_config.yml``
```yaml
---
CLUSTER_NUM: 2
```

## vagrant_config.yml settings file
- Most of the variables including played playbooks can be overriden <br/>
    by editing the ``vagrant_config.yml`` file, read the Vagrantfile

## control
- [./manage](./manage): <br>/
  main entry point
    - **up**: start (create) the vm & mount
    - **down**: umount && stop the vm
    - **ssh**: helper to go inside the VM
    - **sshgen**: helper to generate a ssh client config file
    - **mount**: mount the VM root to local/mountpoint via sshfs
    - **umount**: umount the local/mountpoint sshfs mountpoint
    - **export**: export a VM to a packaged box
    - **import**: import a VM from a packaged box
- [./common.sh](./common.sh):<br/>
  commmon shell helpers

### Scripts related to the vagrant provisioning
- [./Vagrantfile](./Vagrantfile):<br/>
  Vagrantfile to contruct the vm
- The provisioning procedure consists in:
    - execute the pre provision script
        - sync authorized keys from ubuntu to root
        - install corpusops
    - play ansible playbooks
    - execute the post provision script

### Note about skipping/forcing playbooks
- You can use ``[SKIP_|FORCE_]_var`` environment variables to skip/force most playbooks or   code parts, just look at Vagrantfile and playbook to find and use them.
- The vagrantfile load inside machine CFG any ``SKIP/FORCE\\ env var
- eg

```sh
FORCE_INSTALL_SSHFS=1 vagrant up # will force sshfs install even if already done
```

### Bring this setup inside your app
- Adapt/Arrange your workflow to clone [this repo](https://github.com/corpusops/corpusops.bootstrap.git) inside a subfolder of your project
- Symlink or Copy/Edit/adapt this [Vagrantfile](./Vagrantfile) to point to corpusops Vagrantfile_commone.rb
- Symlink [manage](./manage)
- Tweak ansible setup (inject your custom playbooks if needed)
- You are done for ``manage up``
    - It will run the install of corpusops if not done

