# Vagrant based setup for corpusops based projects

## <a name="variables"/>Setup variables

- Core variables
  ```sh
  export A_GIT_URL="git@gitlab.x-x.net:foo/bar.git"
  export COPS_CWD="$HOME/devel/<your project>"  # where you want to checkout the code
  # If you know that a vm is avaiable for download (rsync) (See the project's README)
  export FTP_URL=<tri>@ftp.x-x.net:/srv/projects/*/data/*/nobackup/vm_bar/*-*box
  ```

## <a name="install"/>Install Vagrant and corpusops
- We provide disposable dev environments provisioned
  via the corpusops framework [corpusops](https://github.com/corpusops/corpusops.bootstrap.git)
- First thing you need is to clone recursivly your project
  code inside a dedicated folder which will host the vm.

    ```sh
    git clone --recursive $A_GIT_URL $COPS_CWD
    cd $COPS_CWD
    git submodule init
    git submodule update --recursive
    ```

- From there you get two options
    1. If you already have ``corpusops.bootstrap``, or if you want to get one
       that you 'll share in the future with other projects,
       clone it somewhere and a symlink will be in this subfolder: ``./local/corpusops.bootstrap``.

        ```sh
        # export COPS_ROOT=$HOME/common_corpusops/ ;  # default: ~/corpusops/corpusops.bootstrap
        cd $COPS_CWD
        ./.ansible/scripts/download_corpusops.sh
        ```

    2. Or if you just want to have a local copy of ``corpusops.bootstrap``, just issue

        ```sh
        export SKIP_COPS_FROM_SYSTEM=1
        ./.ansible/scripts/download_corpusops.sh
        ```

- Be sure that your ``corpusops.bootstrap`` copy is up to date
  and operational, specially if reusing it from other projects.

    ```sh
    cd $COPS_CWD
    ./.ansible/scripts/setup_corpusops.sh
    ```

- Setup the base ansible stuff

    ```sh
    cd $COPS_CWD
    ./.ansible/scripts/setup_ansible.sh
    ```

- You can change the options of the VM that we are going to create
  [note this README](https://github.com/corpusops/corpusops.bootstrap/blob/master/hacking/vagrant/README.md)
  et [this file containing useful variables](https://github.com/corpusops/corpusops.bootstrap/blob/master/hacking/vagrant/Vagrantfile_common.rb),
    - <a name="vaguptodate"/> Please note all of **required vagrant plugins** that are detailed inside
    - Also, verify twice that your VirtualBox & vagrant tools are *up-to-date*.
    - **However** if in the next step, you are going to use a
      **prebacked** vm done by your fellow teamates,
      this file will be overwritten, so dont touch it for the first run.

        ```sh
        # mostly you'll edit the vm unique NUM
        # but do not forget to check the README for vagrant plugins
        # WARNING: if you use te box uimport on next step this file will be
        # overwritten by the imported box one
        $EDITOR vagrant_config.yml
        ```

- Now you have TWO options:
    - Generally use a prebacked VM for your project only and only if it exists
    - Or make a new VM with a slightly longer build/provisioning time

### <a name="prebacked"/> With the prebacked VM
If someone does have already build a VM for this project,
you should start from there and it will save you precious minutes.

```sh
vm_file=$(basename $FTP_URL)
# We go inside project top folder (defined in your top readme)
cd $COPS_CWD
# We get the VM
rsync -azvP $FTP_URL ./local/$vm_file
# Note that the further command will overwrite your local vagrant_config.yml (backup it !?)
./vm_manage import ./local/$vm_file
./vm_manage up
```

Note that you should always use the prebacked vm !
This will save you precious minutes, if you dont use it on the VM START, the full provision
procedure may run, not fully but the amount of checks done will make a long procedure on the overall.
Website wont be reinstaller nor destrcuted, but it will be a long procedure nevertheles.

**Note that the VM is still accessible during provisionning, and you can play with it with another shell (like
mounting it if you cant wait the end of the former procedure.**

**After importing your VM, moreover the first time, it is possible that the vbgest plugin
update stuff inside the vm. Sometime, the provision will fail, so just redo it one time.**

Below on the doc, on the chapter [Access to the VM](#vmhosts), you have the commands
to extract the IP of the VM, copy/paste the IP in you /etc/hosts:

```sh
echo "192.168.XX.X corpusopsXX-X.vbox.local <project>.vbox.local" | sudo tee -a /etc/hosts
```

Then access vm website on: ``http://<project>.vbox.local`` /  ``https://<project>.vbox.local``

To go in the vm (SSH), eg for drupal to use console ou drush, it's `vm_manage ssh`.

To edit code, there is a sshfs share, documented below.

Look at the **FAQ** chapter or go up to the **From scratch** Section.


### <a name="scratch"/>From scratch

Here, we are going to reconstruct from scratch the VM without importing a prebacked one.

We edit the vm conf file
    ```sh
    $EDITOR vagrant_config.yml
    ```

- We put something like :

    ```yaml
    ---
    CLUSTER_NUM: 27
    MACHINE_NUM_START: 1
    MEMORY: 2048
    CPUS: 2
    ```

- Then we start

    ```sh
    ./vm_manage provision
    ```

- In case of failure, check first that vagrant & virtualbox are up to date
- You can clone/adapt this repo to deal with details of your local cluster.


You should have then a one-time-login available.

## FAQ

### <a name="vcommon"/> Where is the common vagrant code that the Vagrantfile points to
- Common setup use by the vm is in [hacking/vagrant](https://github.com/corpusops/corpusops.bootstrap/tree/master/hacking/vagrant),
   in case you are curious

### <a name="stop"/>Stop VM

```sh
vm_manage down
```

### <a name="start"/>Start VM

```sh
vm_manage up
```

### <a name="stopprov"/>OMG, i launched provision but i did not want to
Long, huh ?

```sh
CONTROL+C
```

### <a name="remount"/>I shut down the provision procedure, how do I put back the sshfs link ?
You should have called `--no-provision`, But, after, all, after <Control-c>

```sh
vm_manage mount
```

### <a name="umount"/>How do i umount manually the VM

```sh
vm_manage umount
```

### <a name="sshto"/>Going inside the vm, with ssh

```sh
vm_manage ssh
```

### <a name="editor"/>Where do i link my EDITOR (IDE) & where to edit the code, in or out the VM ?
- Rules are simples
    - Code tied to deployment is **mostly out** of the VM (ansible, vagrant files)
    - Code of the APP is **inside the VM** or via the **SSHFS** share and
      synchronnised **the first time only** unless forced (for non prebacked VM only)
- To facilitate the access of the files inside the VM, (to use your favorite EDITOR,
  we integrated a **sshfs** share.
  This one allow you to mount a VM folder inside your box local filesystem (`local/mountpoint/<vm>`) :
- In other words, localhost code only use is for deploying inside the VM,
  to edit app code, edit directly inside the vm VIA THE **SSHFS** share.

    ```sh
    ls -d local/mountpoint/corpusops*-*/
    ls -alh local/mountpoint/corpusops*-*/
    ```

- Once the vm started (up), you should view it's filesystem under this folder,
  you should certainly wire your IDE/EDITOR here

    ```sh
    local/mountpoint/corpusopsX-X/srv/projects/<project>/project
    ```

- You can restart the sshfs mount with:

    ```sh
    ./vm_manage mount
    (...)
    [cops_vagrant] sshfs -F .vagrant/cops-sshconfig-corpusopsX-X vagrant:/ local/mountpoint/corpusopsX-X
    ```

### <a name="upglue"/>Update your provision (deploy) code

```sh
cd $COPS_CWD
# un git pull from there just update deploy glue
git pull --recurse-submodules=yes
# DONT FORGET SUBMODULES IF ANY
git submodule init
git submodule update --recursive
./.ansible/scripts/setup_corpusops.sh
```

After you just have to launch VM with ``vm_manage provision``, and take a very BIG coffee/tea.

### <a name="upcode"/>Update your app code (manips git)
```sh
cd $COPS_CWD
./vm_manage mount
cd local/mountpoint/corpusops*/srv/projects/*/project
git pull --rebase
```

- Then, if DRUPAL, look the step *Update your website dabase*.

### <a name="vagrantboxes"/>Maintenance of vagrant boxes
- To save hard drive space, you may have time to time to removed imported box which
  stay in the vagrant cache, you can list them

    ```sh
    vagrant box list
    ```
- And remove with

    ```sh
    vagrant box remove <id>
    ```
- Vagrant may also cleanup not correctly on import and export, and you can cleanup things in<br/>
  ``~/.vagrant.d/tmp/``

### <a name="scode"/>Symlink your project code folders
Not bad:

```sh
cd $COPS_CWD
for i in $(ls -d local/mountpoint/corpusops*-*);do
for j in $(ls -d $i/srv/projects/*);do
ln -s $j project-$i-$(basename $j)
done
done
```

### <a name="vmhosts"/>Access the VM websites
- Add a line in your `/etc/hosts`, which depends of the VM IP Address:

    ```sh
    # ./vm_manage ssh ip addr |grep 192.168|awk '{print $2}'|sed -re "s|/.*||g"
    192.168.xx.x
    ```

- $EDITOR /etc/hosts

    ```raw
    192.168.xx.x corpusopsXX-X.vbox.local www.<project>.vbox.local <project>.vbox.local
    ```

If you have searching for the name supported by this VM, never hesitate to look its `/etc/hosts`.
It should most of the times contain the names, remember that it's then not `127.0.0.1` but the VM IP (``192.168.xx.xx``).

### <a name="ansiblehand"/>Launch ansible commands by hand
- When we do `vm_manage up`, we can see long ``ansible`` command lines, you can copy/paste them and adapt to replay deploy parts, it will work.
- You should in any case execute ansible from the top folder
 of the project from outside the VM (directly from localhost)
- vagrant should run once for the inventory file to be
  available
- Instead of copy pasting what's vagrant generate, you can
  also use our ansible wrappers, which are simpler:

    ```sh
    .ansible/scripts/call_ansible.sh -v \
     --inventory-file=.vagrant/provisioners/ansible/inventory \
     -e@.ansible/vaults/vagrant.yml \
     -e cops_supereditors="$(id -u)" \
     local/corpusops.bootstrap/playbooks/corpusops/provision/vagrant/pkgmgr.yml
    ```
- See the **-e@FILE** cli switchs, those files contain variables to be applied to your environment.
- See "**cops_supereditors**, this indicate that from outside the VM, with your
  favourite editor, you should be able to edit files from **supereditor_paths** (the code is in those paths by default)

### <a name="only_steps"/>Launch ansible commands, & deploy step by step: ``only_steps``
- Look your App steps: ``.ansible/playbooks/tasks/app_steps.yml``
- You should then use a combination of a playbook, ``only_steps=true`` for your to select which
  deployment steps to execute and not to relaunch the whole thing.
- Eg, to redo on the project ``xxx``, the steps ``zzz`` && ``yyy``:

    ```sh
    .ansible/scripts/call_ansible.sh -v \
     --inventory-file=.vagrant/provisioners/ansible/inventory \
     -e@.ansible/vaults/vagrant.yml  \
     -e cops_supereditors="$(id -u)" \
     .ansible/playbooks/site*vag*l \
     --skip-tags play_db \
     -e "{only_steps: True, \
          cops_xxx_s_setup_yyy: true, \
          cops_xxx_s_setup_zzz: true}"
    ```

### override nginx templates
- [modify nginx](./modify.md#nginx)

