# Vagrant based setup for corpusops based projects
- Common setup is in [hacking/vagrant](https://github.com/corpusops/corpusops.bootstrap/tree/master/hacking/vagrant)

## Install Vagrant for corpusops
- We provide disposable dev environments provisioned
  via the corpusops framework [corpusops](https://github.com/corpusops/corpusops.bootstrap.git)
- First thing you need is to clone recursivly your project
  code inside a dedicated folder which will host the vm.

    ```sh
    git clone --recursive $GIT_URL $COPS_CWD
    ```

- From there you get two options
    1. If you already have ``corpusops.bootstrap``, or if you want to get one
       that you 'll share in the future with other projects,
       clone it somewhere and syhmlink it in this subfolder: ``./local/corpusops.bootstrap``.
        1. Install (do this step only once per project)

            ```sh
            export cops=$HOME/common_corpusops/
            mkdir $COPS_CWD
            cd $COPS_CWD
            if [ ! -e local ];then mkdir local;fi
            if [ ! -e local/corpusops.bootstrap ];then ln -s local/corpusops.bootstrap $cops;fi
            mkdir -p "$cops"
            ./.ansible/scripts/download_corpusops.sh
            ./.ansible/scripts/setup_corpusops.sh
            ```

    2. Or if you just want to have a local copy of ``corpusops.bootstrap``, just issue

        ```sh
        ./.ansible/scripts/download_corpusops.sh
        ./.ansible/scripts/setup_corpusops.sh
        ```

- Be sure that your ``corpusops.bootstrap`` copy is up to date
  and operational, specially if reusing it from other projects.

    ```sh
    ./.ansible/scripts/setup_corpusops.sh
    ```

- Be sure that all of your git submodules are checked out

    ```sh
    git submodule init
    git submodule update --recursive
    ```

- You can change the options of the VM that we are going to create
  [note this README](https://github.com/corpusops/corpusops.bootstrap/blob/master/hacking/vagrant/README.md)
  et [this file containing useful variables](https://github.com/corpusops/corpusops.bootstrap/blob/master/hacking/vagrant/Vagrantfile_common.rb),
- Please note all of **required vagrant plugins** that are detailed inside/
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

Now you have TWO options:
    - Make a new VM with a slightly longer build/provisioning time
    - OR use a prebacked VM for your project only and only if it exists

### With the prebacked VM

If someone does have already build a VM for this project,
you should start from there and it will save you precious minutes.

```sh
# We go inside project top folder (defined in your top readme)
cd $COPS_CWD
# We get the VM
rsync -azvP $FTP_URL ./
# Note that the further command will overwrite your local vagrant_config.yml (backup it !?)
./vm_manage import $PWD/<project>-corpusopsXX-X.box
# Note that important --no-provision, VERY VERY IMPORTANT to save you time, MANY MANY TIME.
./vm_manage up --no-provision
```

Note that you should always use `--no-provision`, never forget to use it each morning !
This will save you precious minutes, if you dont use it on the VM START, the full provision
procedure may run, not fully but the amount of checks done will make a long procedure on the overall.
Website wont be reinstaller nor destrcuted, but it will be a long procedure nevertheles.

**Note that the VM is still accessible during provisionning, and you can play with it with another shell (like
mounting it if you cant wait the end of the former procedure.**

**After importing your VM, moreover the first time, it is possible that the vbgest plugin
update stuff inside the vm. Sometime, the provision will fail, so just redo it one time.

Below on the doc (*Accéder aux sites web de la VM*), youn have the commands
to extract the IP of the VM, copy/paste the IP in you /etc/hosts, par exemple:

```sh
echo "192.168.XX.X corpusopsXX-X.vbox.local <project>.vbox.local" | sudo tee -a /etc/hosts
```

Then  [access vm website](http://<project>.vbox.local/)

To go in the vm (SSH), eg for drupal to use console ou drush, it's `vm_manage ssh`.

To edit code, there is a sshfs share, documented below.

Look at the **FAQ** chapter or go up to the **From scratch** Section.


### From scratch

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
    ./vm_manage up
    ```

- In case of failure, check first that vagrant & virtualbox are up to date
- You can clone/adapt this repo to deal with details of your local cluster.

# Access the VM websites
- Add a line in your `/etc/hosts`, which depends of the VM IP Address:

    ```sh
    # ./vm_manage ssh ip addr |grep 192.168|awk '{print $2}'|sed -re "s|/.*||g"
    192.168.xx.x
    ```

- $EDITOR /etc/hosts

    ```raw
    192.168.xx.x corpusopsXX-X.vbox.local www.<project>.vbox.local <project>.vbox.local
    ```

Si vous cherchez les noms supportés par cette VM n'hésitez pas à regarder le `/etc/hosts` de la VM elle-même, elle contient ces noms,
juste que vous là c'est pas `127.0.0.1` que vous voulez taper mais bien l'IP de la VM depuis votre host.

## DRUPAL: Go inside the site
- Time is up for going inside the vm and issue the following drush command

    ```sh
    vm_manage ssh
    root@corpusopsXX-X: cd /srv/projects/*/project
    root@corpusopsXX-X: sbin/drush uli
    http://<project>.vbox.local/user/reset/1/xx/km-vxx/login
    ```

You should have then a one-time-login available.

# Edit the code in the right PLACE, in or out the VM
- Rules are simples
    - Code tied to deployment is **mostly out** of the VM (ansible, vagrant files)
    - Code of the APP is **inside the VM** and synchronnised the first time (for non prebacked VM only)
- To facilitate the access of the files inside the VM, (to use your favorite EDITOR, we integrated a **sshfs** share.
  This one allow you to mount a VM folder inside your box local filesystem (`local/mountpoint/<nom vm>`) :

- Once the vm started (up), you should view it's filesystem under this folder

    ```sh
    ls -d local/mountpoint/corpusops*-*/
    ls -alh local/mountpoint/corpusops*-*/
    ```

- You can restart the sshfs mount with:

    ```sh
    ./vm_manage mount
    (...)
    [cops_vagrant] sshfs -F .vagrant/cops-sshconfig-corpusopsXX-X vagrant:/ local/mountpoint/corpusopsXX-X
    ```
- Wire your IDE/EDITOR here, eg to reach ``/srv/projects/*/project/``,
  you should wire your editor here ``local/mountpoint/corpusopsXX-X/srv/projects/*/project/``.
- When we issue `vm_manage down` that filesystem is unlinked,
  **it is recommanded to close the editor prior stopping vm**
- **Attention**: on your filesystem, you also have a copy of the project which is still present after VM shutdown.
  You can and should often do a `git pull`,
  or `git submodule update --recursive` from there,
  as the deployment script use that one clone.
  To be clear: inside the vm there is another clone, a copy of the code,
  which is distinct from the one you clone outside of the VM even if it looks like the same.

# FAQ

## Stop VM

```sh
vm_manage down
```

## Start VM

```sh
vm_manage up --no-provision
```

## OMG, i launched provision but i did not want to
Long, huh ?

```sh
CONTROL+C
```

## I§ shut down provision, how i put on back the sshfs link ?
You should have called `--no-provision`, But, after, all, after <Control-c>

```sh
vm_manage mount
```

## Going inside the vm, with ssh

```sh
vm_manage ssh
```

## Where do i link my EDITOR (IDE)
- Inside the **sshfs share**, **ATTENTION**,
  not on the code directly inside **$COPS_CWD** on your localhost.
- localhost code only use is for deploying inside the VM,
  to edit app code, edit directly inside the vm VIA THE **SSHFS** share.

```sh
local/mountpoint/corpusopsXX-X/srv/projects/<project>/project
```

## Browsing the app installed inside the VM
- cf *Access the VM websites* (upper)(for`/etc/hosts`).
- Website awaits requests on  http://<project>.vbox.local/](http://<project>.vbox.local/)


## ZOPE: get the web admin password
- Login is generally: admin
- Password
```sh
./vm_manage ssh \
'for i in /etc/*secrets/*zope_admin_password;do printf "$(basename $i): "$(cat $i)\\n;done'\
|awk '!a[$0]++'|sort -nk2
```

## Update your provision code

```sh
cd $COPS_CWD
# un git pull from there just update deploy glue
git pull --recurse-submodules=yes
# DONT FORGET SUBMODULES IF ANY
git subhmodule init
git submodule update --recursive
./.ansible/scripts/setup_corpusops.sh
```

After you just have to launch VM without `--no-provision`, and take a very BIG coffee/tea.

### Update your app code (manips git)
```sh
cd $COPS_CWD
./vm_manage mount
cd local/mountpoint/corpusops*/srv/projects/*/project
git pull --rebase
```

- Then, if DRUPAL, look the step *Update your website dabase*.

### DRUPAL: Update your website dabase
After code update, you should also do this step
```
# puis on lance le post-update pour faire tourner les updb, config-sync et autres joyeusetés
cd -
vm_manage ssh
root@corpusopsXX-X:~# cd /srv/projects/*/
root@corpusopsXX-X:~# cd /srv/projects/s*/project/
root@corpusopsXX-X:/srv/projects/*/project# sbin/post_update.sh
+ Testing relative link /srv/projects/*/project/www/sites/default exists

 * 0- Do you want to run a drush -y updb ? [o/n]: o
  - So we run drush -y updb
 [success] No database updates required.

 * 1- Do you want to run a drush -y cim ? [o/n]: o
  - So we run drush -y cim
+ drush -y cim
 [notice] There are no changes to import.

 * 2- Clear all caches via drush ? [o/n]: o
+ drush -y cr
 [success] Cache rebuild complete.
```

## Symlink your project code folders
Not bad:

```sh
cd $COPS_CWD
for i in $(ls -d local/mountpoint/corpusops*-*);do
for j in $(ls -d $i/srv/projects/*);do
ln -s $j project-$i-$(basename $j)
done
done
```

## Launch ansible commands, & deploy step by step
- When we do `vm_manage up`, we can see long ``ansible`` command lines, you can copy/paste them and adapt to replay deploy parts, it will work.
- You should in any case execute ansible from the top folder
 of the project from outside the VM (directly from localhost)
- vagrant should run once for the inventory file to be
  available
- Instead of copy pasting what's vagrant generate, you can
  also use our ansible wrappers, which are simpler:

    ```sh
    .ansible/scripts/setup_core_variables.sh
    .ansible/scripts/call_ansible.sh -v \
     --inventory-file=.vagrant/provisioners/ansible/inventory \
     -e@local/corevars.yml -e@.ansible/vaults/vagrant.yml \
     -e cops_supereditors="$(id -u)" \
     local/corpusops.bootstrap/playbooks/corpusops/provision/vagrant/pkgmgr.yml
    ```
- See the **-e@FILE** cli switchs, those files contain variables to be applied to your environment.
- See "**cops_supereditors**, this indicate that from outside the VM, with your
  favourite editor, you should be able to edit files from **supereditor_paths** (the code is in those paths by default)

## Launch ansible commands, & deploy step by step; only_steps
- Look your [App steps](.ansible/playbooks/tasks/app_steps.yml)
- You should then use a combination of a playbook, ``only_steps=true`` for your to select which deployment steps to execute and not to relaunch the whoething.
- Eg, to redo php-fpm, sync local code from localdir to inside the vm and
  reinstall the app (do a manual drush sql-drop via ``vm_manage ssh`` before):

    ```sh
    .ansible/scripts/setup_core_variables.sh
    .ansible/scripts/call_ansible.sh -v \
     --inventory-file=.vagrant/provisioners/ansible/inventory \
     -e@local/corevars.yml -e@.ansible/vaults/vagrant.yml  \
     -e cops_supereditors="$(id -u)" \
     .ansible/playbooks/site*vag*l \
     --skip-tags play_db \
     -e "only_steps=True cops_drupal_s_fpm=true"
    ```

