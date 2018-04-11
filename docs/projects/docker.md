# docker

## Docker images provision & usage
* All of our projects consider docker as a first class citizen but:
    * We still provision images with ansible: at this time **NO SECRET**, we only build general purpose images.
    * We reconfigure them upon the container (re)start also with ansible, and we generally use ``systemd`` as the process supervisor.
    * Here we inject the password to decode and generate configs from secrets.
* For this, as ansible will generally need a lot of variables to manipulate the deployment <br/>
  and we need to load alternate build settings to adapt the procedure to a specific env,<br/>
  we use ``ansible variables yaml files`` inside the ``.ansible/vaults`` folder called vaults, one encrypted and maybe one in clear<br/>
  eg: ``.ansible/vaults/dockertest.yml`` (encrypted)  and ``.ansible/vaults/docker.clear.yml``. the  ``clear`` favor can me missing.
  Both file can be encrypted or not, ansible decrypt them via its built-in encryption mecanism, Please see corpusops Vaults managment in documentation.
* We generally use this convention for the application Dockerfiles:
    * ``Dockerfile``: base image suitable for prod (``systemd``) + code injection
    * ``docker-compose.yml``: Docker compose file sample to launch the ``prod`` image
    * ``Dockerfile.dev``: image (child of base image) that is suitable in dev (dev tools, and suitable for mounting source folder as volumes inside
    * ``docker-compose-dev.yml``: Docker compose file sample to launch the ``dev``
* You can specify the ``vault`` set you want via the ``APP_ENV_NAME=<vault>`` build arg.
* You can tell to not refresh corpusops automatically upon rebuilds via ``SKIP_COPS_UPDATE=y``
* eg:

    ```sh
    docker build --squash  -t corpusops/yourproject:latest . -f Dockerfile \
        [--build-arg=APP_ENV_NAME=docker] \
        [--build-arg=SKIP_COPS_UPDATE=y]
    # or
    docker build --squash  -t corpusops/yourproject:dev    . -f Dockerfile.dev \
        [--build-arg=APP_ENV_NAME=dockerdev] \
        [--build-arg=SKIP_COPS_UPDATE=y]
    ```
* In case you are debugging a build and want to speed up things:
    * You can copy/paste the Dockerfile and uncomment and read the part about ``corpusops.boostrap bind mount``<br/>
      if you are hacking yourself corpusops.bootstrap and want to load live modififications inside the build environment.
    * You can copy paste one dockerfile and adapt the ``FROM`` instruction to use a more appropriate layer, and
      adapt the desired ansible call to use ``{only_steps: true, your_step: true}``
* Build order:
    1. Build first: **mycorp/myproject:<tag>** image
    2. build: **mycorp/myproject:<dev>** image
        * the build or to speed up developpment and dosen't redo everything from the beginning
    3. Build any env specific image (test, prodenv, etc).

* At runtime, we launch the image which reconfigure itself through either enviromnent variables (A_RECONFIGURE/A_POSTCONFIGURE) or via the /setup/reconfigure|/setup/postconfigure.yml files, maybe the vault password injected in the env via the 'CORPUSOPS_VAULT_PASSWORD_<env>' envar.

## Detailed example
### <a name="variables"/>Setup variables

- Core variables
  ```sh
  export A_GIT_URL="git@gitlab.x-x.net:foo/bar.git"
  export COPS_CWD="$HOME/devel/<your project>"  # where you want to checkout the code
  # If you know that a vm is avaiable for download (rsync) (See the project's README)
  export FTP_URL=<tri>@ftp.x-x.net:/srv/projects/*/data/*/nobackup/vm_bar/*-*.tar
  ```

### <a name="install"/>Install docker and corpusops
- Install docker and docker-compose at their most recent versions.
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
### <a name="prebacked"/> With the prebacked VM, development mode
If someone does have already build an image for this project,
you should start from there and it will save you precious minutes.

EG:
```sh
docker load <the_image_tarball>
# if the image is compressed, you can do something like that:
# bzip2 -kdc corpusops-yourproject-dev.tar.bz2|docker load
SUPEREDITORS=$(id -u) docker-compose \
  -f d*-compose.yml -f d*-compose-dev.yml up -d [--force-recreate] -t 0 yourproject;\
  docker logs -f setupsyourprojectproject_yourproject_1
```

You may want to omit ``--force-recreate`` to keep using your container, day after day,
without creating after each ``docker-compose`` call.

Below on the doc, on the chapter [Access to the VM](#vmhosts), you have the commands
to extract the IP of the VM, copy/paste the IP in you /etc/hosts:

```sh
echo "192.168.XX.X corpusopsXX-X.corpusops.local <project>.corpusops.local" | sudo tee -a /etc/hosts
```

Then access vm website on: ``http://<project>.corpusops.local`` /  ``https://<project>.corpusops.local``

To go in the vm (SSH), eg for drupal to use console ou drush, it's `docker exec -ti <container> bash`

Look at the **FAQ** chapter or go up to the **From scratch** Section.


### <a name="scratch"/>From scratch
- You can build in order the regular (``:latest``) tag then after, the development (``:dev``) tag of your project image.
- 1.

    ```sh
    docker build --squash -t corpusops/yourproject     . -f Dockerfile\
        [--build-arg=SKIP_COPS_UPDATE=y] [--build-arg=APP_ENV_NAME=docker]
    ```
- 2.

    ```sh
    docker build --squash -t corpusops/yourproject:dev . -f Dockerfile.dev\
        [--build-arg=SKIP_COPS_UPDATE=y] [--build-arg=APP_ENV_NAME=dockerdev]
    ```

## FAQ
### <a name="vmhosts"/>Access the VM websites
- Add a line in your `/etc/hosts`, which depends of the Docker IP Address:

    ```sh
    # docker exec <yourcontainer> ip addr show dev eth0|egrep ".*\..*\..*\."|awk '{print $2}'|sed -re "s|/.*||g"
    172.19.102.2
    ```

- $EDITOR /etc/hosts

    ```raw
    172.19.102.2 corpusopsXX-X.corpusops.local www.<project>.corpusops.local <project>.corpusops.local
    ```

#### <a name="ansiblehand"/>Launch ansible commands by hand
- When we do `docker-compose up`, we can see long ``ansible`` command lines,
  you can copy/paste them and adapt to replay deploy parts, it will work.
- You should in any case execute ansible from the top folder
  of the project from outside the VM (directly from localhost)
- vagrant should run once for the inventory file to be
  available
- Instead of copy pasting what's vagrant generate, you can
  also use our ansible wrappers, which are simpler:

    ```sh
    docker exec -ti <container> bash
    .ansible/scripts/call_ansible.sh -v \
     -e@.ansible/vaults/vagrant.yml \
     local/corpusops.bootstrap/playbooks/corpusops/provision/vagrant/pkgmgr.yml
    ```
- See the **-e@FILE** cli switchs, those files contain variables to be applied to your environment.
- See "**cops_supereditors**, this indicate that from outside the VM, with your
  favourite editor, you should be able to edit files from **supereditor_paths** (the code is in those paths by default)

#### <a name="show_only_steps"/>Show ansible deploy steps: ``only_steps``
- Look your App steps: ``.ansible/playbooks/roles/*_step/tasks/main.yml``
- You should then use a combination of a playbook, ``only_steps=true`` and a ``playbook.yml`` to view all steps that you can select
    ```sh
    docker exec -ti <container> bash
    .ansible/scripts/call_ansible.sh -v \
     .ansible/playbooks/site*vag*l \
     -e "{cops_vars_debug: true, only_steps: true}"
    ```

#### <a name="only_steps"/>Launch ansible commands, & deploy step by step: ``only_steps``
- Look your App steps: ``.ansible/playbooks/tasks/app_steps.yml``
- Eg, to redo on the project ``xxx``, the steps ``zzz`` && ``yyy``:

    ```sh
    docker exec -ti <container> bash
    .ansible/scripts/call_ansible.sh -v \
     .ansible/playbooks/site*vag*l \
     --skip-tags play_db \
     -e "{only_steps: True, \
          cops_xxx_s_setup_yyy: true, \
          cops_xxx_s_setup_zzz: true}"
    ```

#### override nginx templates
- [modify nginx](./modify.md#nginx)

#### Save your image to share it
```sh
docker save corpusops/yourproject:dev|bzip2 > corpusops-yourproject-dev.tar.bz2
```

## Running docker images in Rancher2 [WIP: Rancher2 will be release in early 08/18!]
Rancher2 will help you managing stacks, its the glue between the images, docker compose and kubernetes

## In dev and prod: rancher2
- Initiate a cluster controller:

    ```
    sudo docker run -d --restart=unless-stopped -p 9080:80 -p 9443:443 \
        -v /var/lib/rancher:/var/lib/rancher --name=rancherserverp  rancher/server:preview
    ```
- Choose an IP address or a DNS alias for the controller (add it for example in your ``/etc/hosts``  of any host controller by rancher, or in a central DNS server)
- Firewall the ports ``9080`` & ``9443`` and choose a complex and appriopriate admin password.
- Rancher is a thin layer to kuberneges which has 3 plantes: data; control; compute.
    - Each member of a plane should see and contact the other members and the controller on it's relative service ports.
- Add cluster:
    - type: custom
    - name: localdev
    - version: certainly the highest of each
    - docker version: Allow unsupported versions
- Select the roles that you want on each node of your cluster and run the appriopriate and given join command.
    - This mean that on a dev laptop, you certainly want all the roles (3 atm: etcd, control, worker).

## FAQ
### File not updating in container after edit
* In dev, My edition to a particular file in a container is not refreshing, certainly due to [moby/#15793](https://github.com/moby/moby/issues/15793),
  you need to configure your editor, eg vim to use atomic saves (eg: ``set noswapfile``)
