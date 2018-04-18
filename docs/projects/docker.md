 docker

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

### Specifying variables and secrets
* There is multiple way to intruct docker to inject ansible collection of variables.
    * ``A_ENV_NAME`` build_arg/env_var can be used to specify a specific vault at ``build`` stage or  ``runtime`` stage
    * ``CORPUSOPS_VAULT_PASSWORD_<ENV>"`` env var at runtime to inject the vault decryption passwords, **AT RUNTIME ONLY**.
* At runtime, we launch the image which reconfigure itself through either enviromnent variables and/or files
    * The provision is done by rerunning the ansible provision, with well placed variables that redo specific parts of the provision
    * Generally we use systemd, and <br/>
      we reconfigure some things before systemd starts,<br/>
      and some other after, when services are available (eg to configure databases & users)
    * ``A_RECONFIGURE`` / ``A_POSTCONFIGURE`` env vars (via ``docker -e`` or ``docker-compose / service:environment``
    * ``/setup/reconfigure.yml`` / ``/setup/postconfigure.yml`` files

## Detailed example of installing a development enviroment based on docker
### <a name="variables"/>Setup variables

- Core variables
  ```sh
  export A_GIT_URL="git@gitlab.x-x.net:foo/bar.git"
  export COPS_CWD="$HOME/devel/<your project>"  # where you want to checkout the code
  # If you know that a vm is avaiable for download (rsync) (See the project's README)
  export FTP_URL=<tri>@ftp.x-x.net:/srv/projects/*/data/*/nobackup/vm_bar/
  ```

- First thing you need is to clone recursivly your project
  code inside a dedicated folder which will host the vm.

    ```sh
    git clone --recursive $A_GIT_URL $COPS_CWD
    cd $COPS_CWD
    git submodule init
    git submodule update --recursive
    # if you dont have the image locally
    rsync -azv $FTP_URL/ "./local/image/"
    ```

### <a name="install"/>Install docker and corpusops
- Install docker and docker-compose (eg: engine:17.07.0-ce / compose:1.20.1).<br/>
  You can do this manually, or if you are on ubuntu/debian/centos,
  you can install locally corpusops.bootstrap and run the docker role.
    - install corpusops

        ```sh
        .ansible/scripts/download_corpusops.sh
        .ansible/scripts/setup_corpusops.sh
        ```
    - install docker & compose

        ```sh
        local/corpusops.bootstrap/bin/cops_apply_role --sudo -vvvv \
            local/corpusops.bootstrap/roles/corpusops.roles/localsettings_dockercompose/role.yml \
            local/corpusops.bootstrap/roles/corpusops.roles/services_virt_docker/role.yml
        ```

### <a name="datapopulate"/> Volumes pre-init
- Populate volumes inside ``local/`` (generally ``local/data`` & ``local/setup``).<br/>
  Do this steps if you have volumes with the image and want to extract them
  (if you have for example not initialazed any database)

    ```sh
    bn=$(  . .a*/scripts/*_deploy_env;echo ${A_GIT_NAMESPACE}_${A_GIT_PROJECT})
    sudo tar xzpvf local/image/${bn}-volumes.tgz
    ```

### <a name="load"/> Load the dockers
- If someone does have already build an image for this project,

    ```sh
    bn=$(. .a*/scripts/*_deploy_env;echo ${A_GIT_NAMESPACE}_${A_GIT_PROJECT})
    gzip -dc local/image/${bn}.gz | docker load
    ```


### <a name="prebacked"/>Launch the image
- For reference if the image is systemD based, the workflow is as-is:
    - ansible reconfigure the image before systemd run
    - systemd launch image with services
        - ansible reconfigure again the image with post procedure
          that needs services to be up (like for creating databases and users)
EG:
```sh
# if the image is compressed, you can do something like that:
# bzip2 -kdc corpusops-yourproject-dev.tar.bz2|docker load
SUPEREDITORS=$(id -u) docker-compose \
  -f d*-compose.yml -f d*-compose-dev.yml up -d --no-recreate -t 0;\
  docker logs -f setupsyourprojectproject_yourproject_1
```

You may want to add ``--force-recreate`` instead of ``--no-recreate`` to renew your container, and start fresh, straight from the image.
without creating after each ``docker-compose`` call.

Well, it is ``docker-compose`` basic usage, idea is to use the docker image as-a-VM, recreating or reusing a container along is beyond the scope of this documentation.

Below on the doc, on the chapter [Access to the VM](#vmhosts), you have the commands
to extract the IP of the VM, copy/paste the IP in you /etc/hosts:

```sh
docker exec setupsdjangoproject_django_1 ip route get 1 2>&1|head -n1|awk '{print $7;exit;}'

echo "192.168.XX.X corpusopsXX-X.corpusops.local <project>.corpusops.local" | sudo tee -a /etc/hosts
```

Then access vm website on: ``http://<project>.corpusops.local`` /  ``https://<project>.corpusops.local``

To go in the vm (SSH), eg for drupal to use console ou drush, it's `docker exec -ti <container> bash`

Look at the **FAQ** chapter or go up to the **From scratch** Section.


### <a name="scratch"/>From scratch
- You can build in order the regular (``:latest``) tag then after, the development (``:dev``) tag of your project image.
1.

  ```sh
  docker build --squash -t corpusops/yourproject     . -f Dockerfile\
      [--build-arg=SKIP_COPS_UPDATE=y] [--build-arg=APP_ENV_NAME=docker]
  ```
2.

  ```sh
  docker build --squash -t corpusops/yourproject:dev . -f Dockerfile.dev\
      [--build-arg=SKIP_COPS_UPDATE=y] [--build-arg=APP_ENV_NAME=dockerdev]
  ```

## FAQ
### <a name="vmhosts"/>Access the VM websites
- Add a line in your `/etc/hosts`, which depends of the Docker IP Address:

    ```sh
    docker exec setupsyourprojectproject_yourproject_1 ip route get 1 2>&1|head -n1|awk '{print $7;exit;}'
    172.19.102.2
    ```

- $EDITOR /etc/hosts

    ```raw
    172.19.102.2 corpusopsXX-X.corpusops.local www.<project>.corpusops.local <project>.corpusops.local
    ```

#### <a name="ansiblehand"/>Launch ansible commands by hand
- When we do `docker-compose up`, we can see long ``ansible`` command lines,
  you can copy/paste them and adapt to replay deploy parts, it will work.
- Instead of copy pasting what's vagrant generate, you can
  also use our ansible wrappers, which are simpler:

    ```sh
    docker exec -ti <container> bash
    .ansible/scripts/call_ansible.sh -v \
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
     .ansible/playbooks/site.yml \
     -e "{cops_vars_debug: true, only_steps: true}"
    ```

#### <a name="only_steps"/>Launch ansible commands, & deploy step by step: ``only_steps``
- Look your App steps: ``.ansible/playbooks/tasks/app_steps.yml``
- Eg, to redo on the project ``xxx``, the steps ``zzz`` && ``yyy``:

    ```sh
    docker exec -ti <container> bash
    .ansible/scripts/call_ansible.sh -v \
     .ansible/playbooks/site.yml \
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


### Export and distribute the images (dev & root)
```sh
bns=$( . .a*/scripts/*_deploy_env;echo ${A_GIT_NAMESPACE}/${A_GIT_PROJECT})
bn=$(  . .a*/scripts/*_deploy_env;echo ${A_GIT_NAMESPACE}_${A_GIT_PROJECT})
if [ ! -e local/image ];then mkdir -p local/image;fi
sudo docker save $bns $bns:dev | gzip > local/image/$bn.gz
sudo tar pczvf local/image/${bn}-volumes.tgz local/data/ local/setup
rsync -azvP local/image/ $FTP_URL/
```
